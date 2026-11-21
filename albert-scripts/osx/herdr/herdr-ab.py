#!/usr/bin/env python3
"""herdr-ab: herdr 体验期的补齐脚本（对齐 tmux / tmuxp 习惯）。

只依赖 python3 标准库（兼容 macOS 自带 3.9），通过 herdr 的本地 socket API
发送 newline-delimited JSON 请求。

子命令：
  load <layout.json>   按 tmuxp 风格的 JSON 创建 workspace + tabs（≈ tmuxp load）
  export [--tab ID]    把当前 workspace 导出为同格式 JSON（≈ tmuxp freeze）
  equal [right|down]   当前 tab 所有分割比例均分（≈ tmux select-layout even-*）
  move                 fzf 选目标 tab，把当前 pane 搬过去（≈ tmux join-pane）
  kill <label>         关闭指定 label 的 workspace（≈ tmux kill-session -t）
  call <method> [json] 直接调用任意 socket API 方法（调试用）

socket 解析顺序：$HERDR_SOCKET_PATH → $HERDR_SESSION 对应 session →
默认 ~/.config/herdr/herdr.sock。
"""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
from typing import Any, NoReturn

HERDR_DIR = os.path.expanduser("~/.config/herdr")


# ------------------------------------------------------------------------------
# socket
# ------------------------------------------------------------------------------
def socket_path():
    env_path = os.environ.get("HERDR_SOCKET_PATH")
    if env_path:
        return env_path
    session = os.environ.get("HERDR_SESSION")
    if session and session != "default":
        return os.path.join(HERDR_DIR, "sessions", session, "herdr.sock")
    return os.path.join(HERDR_DIR, "herdr.sock")


def call(method: str, params: dict[str, Any] | None = None) -> dict[str, Any]:
    """发送一个请求并返回 result；出错时打印并退出。"""
    path = socket_path()
    conn = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        conn.connect(path)
    except OSError as err:
        die(f"连接 herdr socket 失败: {path} ({err})，server 是否在运行？")
    req = {"id": "herdr-ab", "method": method, "params": params or {}}
    conn.sendall((json.dumps(req) + "\n").encode())
    buf = b""
    while not buf.endswith(b"\n"):
        chunk = conn.recv(65536)
        if not chunk:
            break
        buf += chunk
    conn.close()
    resp = parse_json(buf.decode(), f"{method} 响应")
    if "error" in resp:
        die(f"{method} 失败: {json.dumps(resp['error'], ensure_ascii=False)}")
    return resp.get("result", {})


def parse_json(text: str, what: str) -> Any:
    try:
        return json.loads(text)
    except ValueError as err:
        die(f"{what} 不是合法 JSON: {err}")


def die(msg: str) -> NoReturn:
    sys.stderr.write(f"herdr-ab: {msg}\n")
    sys.exit(1)


# ------------------------------------------------------------------------------
# load / export：tmuxp 风格 JSON <-> herdr layout 树
# ------------------------------------------------------------------------------
def pane_node(spec: Any, default_cwd: str) -> dict[str, Any]:
    """tmuxp pane 写法 -> herdr pane 节点。支持 null / 字符串命令 / 对象。"""
    node: dict[str, Any] = {"type": "pane", "cwd": default_cwd}
    if spec is None or spec == "":
        return node
    opts: dict[str, Any] = {"shell_command": [spec]} if isinstance(spec, str) else dict(spec)
    spec = opts
    start_dir = opts.get("start_directory")
    if isinstance(start_dir, str) and start_dir:
        node["cwd"] = os.path.expanduser(start_dir)
    if spec.get("label"):
        node["label"] = spec["label"]
    cmds = spec.get("shell_command")
    if cmds:
        if isinstance(cmds, str):
            cmds = [cmds]
        # 跑完命令后回到交互 shell，行为接近 tmuxp send-keys
        shell = os.environ.get("SHELL", "/bin/zsh")
        script = "; ".join(cmds) + "; exec " + shell
        node["command"] = [shell, "-lc", script]
    return node


def even_tree(nodes, direction):
    """把 N 个 pane 串成均分的 BSP 链：ratio = 1/剩余数量。"""
    if len(nodes) == 1:
        return nodes[0]
    return {
        "type": "split",
        "direction": direction,
        "ratio": round(1.0 / len(nodes), 4),
        "first": nodes[0],
        "second": even_tree(nodes[1:], direction),
    }


LAYOUT_DIRECTION = {
    "even-horizontal": "right",
    "main-vertical": "right",
    "even-vertical": "down",
    "main-horizontal": "down",
}


def window_root(win, default_cwd):
    cwd = os.path.expanduser(win.get("start_directory") or default_cwd)
    if win.get("root"):  # 已是 herdr 原生树（export 产物）
        return win["root"]
    panes = win.get("panes") or [None]
    nodes = [pane_node(p, cwd) for p in panes]
    direction = LAYOUT_DIRECTION.get(win.get("layout", "even-horizontal"), "right")
    return even_tree(nodes, direction)


def find_workspace(label):
    for ws in call("workspace.list").get("workspaces", []):
        if ws.get("label") == label:
            return ws
    return None


def cmd_load(path):
    path = resolve_layout(path)
    try:
        with open(path) as fh:
            spec = parse_json(fh.read(), path)
    except OSError as err:
        die(f"读取 {path} 失败: {err}")
    name = spec.get("session_name") or os.path.splitext(os.path.basename(path))[0]
    cwd = os.path.expanduser(spec.get("start_directory") or "~")
    windows = spec.get("windows") or []
    if not windows:
        die(f"{path} 里没有 windows")

    existing = find_workspace(name)
    if existing:
        call("workspace.focus", {"workspace_id": existing["workspace_id"]})
        print(f"workspace '{name}' 已存在（{existing['workspace_id']}），"
              f"已切过去；要重建先 ab.herdr.kill {name}")
        return

    created = call("workspace.create", {"label": name, "cwd": cwd, "focus": True})
    ws_id = created["workspace"]["workspace_id"]
    placeholder_tab = created["tab"]["tab_id"]

    focus_tab = None
    for idx, win in enumerate(windows):
        params = {
            "root": window_root(win, cwd),
            "tab_label": win.get("window_name") or str(idx + 1),
            "focus": False,
        }
        if idx == 0:
            params["tab_id"] = placeholder_tab  # 替换 workspace 自带的空 tab
        else:
            params["workspace_id"] = ws_id
        layout = call("layout.apply", params)["layout"]
        if idx == 0 or win.get("focus"):
            focus_tab = layout["tab_id"]
    if focus_tab:
        call("tab.focus", {"tab_id": focus_tab})
    print(f"已创建 workspace '{name}'（{ws_id}），{len(windows)} 个 tab")


def strip_runtime(node):
    """去掉 pane_id 等运行时字段，保留结构 / label / cwd / command。"""
    node = dict(node)
    node.pop("pane_id", None)
    if node.get("type") == "split":
        node["first"] = strip_runtime(node["first"])
        node["second"] = strip_runtime(node["second"])
    return node


def cmd_export(args):
    if args[:1] == ["--tab"] and len(args) > 1:
        tabs = [call("tab.get", {"tab_id": args[1]})["tab"]]
        ws_id = tabs[0]["workspace_id"]
    else:
        ws_id = call("pane.current")["pane"]["workspace_id"]
        tabs = call("tab.list", {"workspace_id": ws_id}).get("tabs", [])
    ws = call("workspace.get", {"workspace_id": ws_id})["workspace"]
    windows = []
    for tab in tabs:
        layout = call("layout.export", {"tab_id": tab["tab_id"]})["layout"]
        win = {"window_name": tab["label"], "root": strip_runtime(layout["root"])}
        if tab.get("focused"):
            win["focus"] = True
        windows.append(win)
    out = {"session_name": ws["label"], "start_directory": "~", "windows": windows}
    print(json.dumps(out, ensure_ascii=False, indent=2))


def resolve_layout(name: str) -> str:
    if os.path.isfile(name):
        return name
    layout_dir = os.environ.get("HERDR_AB_LAYOUT_DIR") or os.path.join(HERDR_DIR, "layouts")
    for cand in (name, name + ".json"):
        full = os.path.join(layout_dir, cand)
        if os.path.isfile(full):
            return full
    die(f"找不到布局 {name}（查找目录 {layout_dir}）")


# ------------------------------------------------------------------------------
# equal：按叶子数加权均分
# ------------------------------------------------------------------------------
def weight(node, direction):
    """沿 direction 方向的叶子数；方向不同的子树整体算 1 份。"""
    if node.get("type") != "split" or node.get("direction") != direction:
        return 1
    return weight(node["first"], direction) + weight(node["second"], direction)


def plan_ratios(node, path, only, out):
    if node.get("type") != "split":
        return
    direction = node["direction"]
    if only in (None, direction):
        first = weight(node["first"], direction)
        second = weight(node["second"], direction)
        out.append((list(path), round(first / float(first + second), 4)))
    plan_ratios(node["first"], path + [False], only, out)
    plan_ratios(node["second"], path + [True], only, out)


def cmd_equal(args):
    only = args[0] if args else None
    if only not in (None, "right", "down"):
        die("equal 参数只能是 right / down / 留空")
    layout = call("layout.export")["layout"]
    plan = []
    plan_ratios(layout["root"], [], only, plan)
    for path, ratio in plan:
        call("layout.set_split_ratio", {"tab_id": layout["tab_id"], "path": path, "ratio": ratio})
    print(f"{layout['tab_id']}: 已均分 {len(plan)} 个 split")


# ------------------------------------------------------------------------------
# move：fzf 选目标 tab，搬运当前 pane
# ------------------------------------------------------------------------------
def cmd_move(args):
    pane_id = os.environ.get("HERDR_ACTIVE_PANE_ID") or call("pane.current")["pane"]["pane_id"]
    src = call("pane.get", {"pane_id": pane_id})["pane"]
    lines = ["new-tab\t[新建 tab]", "new-workspace\t[新建 workspace]"]
    for ws in call("workspace.list").get("workspaces", []):
        for tab in call("tab.list", {"workspace_id": ws["workspace_id"]}).get("tabs", []):
            if tab["tab_id"] == src["tab_id"]:
                continue
            lines.append(f"{tab['tab_id']}\t{ws['label']} / {tab['label']}  ({tab['pane_count']} panes)")
    try:
        picked = subprocess.run(
            ["fzf", "--reverse", "--delimiter", "\t", "--with-nth", "2",
             "--header", f"move {pane_id} to:"],
            input="\n".join(lines), stdout=subprocess.PIPE, text=True,
        ).stdout.strip()
    except FileNotFoundError:
        die("需要 fzf")
    if not picked:
        return
    target = picked.split("\t", 1)[0]
    if target == "new-tab":
        dest = {"type": "new_tab", "workspace_id": src["workspace_id"]}
    elif target == "new-workspace":
        dest = {"type": "new_workspace"}
    else:
        split = args[0] if args else "right"
        dest = {"type": "tab", "tab_id": target, "split": split}
    call("pane.move", {"pane_id": pane_id, "destination": dest, "focus": True})


# ------------------------------------------------------------------------------
# main
# ------------------------------------------------------------------------------
def main(argv):
    if not argv or argv[0] in ("-h", "--help", "help"):
        print(__doc__)
        return
    cmd, rest = argv[0], argv[1:]
    if cmd == "load":
        if not rest:
            die("用法: herdr-ab load <layout.json|name>")
        cmd_load(rest[0])
    elif cmd == "export":
        cmd_export(rest)
    elif cmd == "equal":
        cmd_equal(rest)
    elif cmd == "move":
        cmd_move(rest)
    elif cmd == "kill":
        if not rest:
            die("用法: herdr-ab kill <workspace-label>")
        ws = find_workspace(rest[0])
        if not ws:
            die(f"没有名为 {rest[0]} 的 workspace")
        call("workspace.close", {"workspace_id": ws["workspace_id"]})
        print(f"已关闭 workspace '{rest[0]}'（{ws['workspace_id']}）")
    elif cmd == "call":
        if not rest:
            die("用法: herdr-ab call <method> [json-params]")
        params = parse_json(rest[1], "params") if len(rest) > 1 else {}
        print(json.dumps(call(rest[0], params), ensure_ascii=False, indent=2))
    else:
        die(f"未知子命令: {cmd}")


if __name__ == "__main__":
    main(sys.argv[1:])
