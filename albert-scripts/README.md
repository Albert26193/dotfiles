# albert-scripts

个人纯 Shell 函数工具集（零 Python 脚本）。设计目标：**最简全量加载 + 两层约定式路由 + 注释即索引 + `ab.lint` 防退化**。

## 1. 目录结构

```text
albert-scripts/
├── export.sh          # 唯一加载入口（由 ~/.zshrc source）
├── config.env         # 全局配置（FS_SEARCH_DIRS / FS_EDITOR 等）
├── README.md          # 本规范文档
├── src/               # 所有由 export.sh 全量加载的纯 shell 函数
│   ├── _utils/        # 内部公共基建（优先加载，不对外暴露，不进 ab 索引）
│   ├── meta/          # 工具集自身元能力：ab（fzf 检索）与 ab.lint（规范校验）
│   ├── osx/           # macOS 相关（apple / proxy）
│   ├── fzf/           # 交互式检索工具（codex / pet / fs）
│   ├── dev/           # 研发、调试、工程初始化（git / gdb / load / env）
│   ├── pkg/           # 包管理、安装、bin 软链（brew / install / link）
│   └── shell/         # 终端复用与日常命令行工具（tmux / clip / pager / bm）
├── assets/            # 静态模板文件（demo.vsc.json / demo.claude.json，供 ab.load.* 读取）
├── bin/               # PATH 可执行脚本（vsc-task，原位保留以兼容既有项目）
└── func/              # 独立任务脚本（claude-save / *.vsc.sh，原位保留以兼容既有项目）
```

## 2. 加载机制

- **不区分 OS，全量加载**：`export.sh` 只读取一次 `config.env`，先递归加载 `src/_utils/`，再按字典序加载 `src/` 下其余分类目录中的所有 `*.sh`。
- **同目录顺序**：每个目录内先加载 `_*.sh`（如 `src/fzf/fs/_common.sh`），再加载其他 `*.sh`。
- **零全局泄露**：`export.sh` 内部 loader 函数执行完后立刻 `unset -f`，不向当前 shell 留存任何临时函数或循环变量；支持 `zsh -f` 与 `bash --norc -e`。

## 3. 两层约定式路由规范

> **一级目录 = 分类标签（不进命令名）；二级 `<domain>.sh` 或 `<domain>/*.sh` = 命令命名空间 `ab.<domain>`。**

| 文件路径 | 合法公开函数 | 合法私有函数 | 说明 |
|---|---|---|---|
| `src/_utils/*.sh` | 禁止 | `_ab.*` | 内部公共库（如 `_ab.ui.green`、`_ab.ui.yn`） |
| `src/meta/ab.sh` | `ab`、`ab.lint` | `_ab.ab.*` | 根入口特例 |
| `src/<cat>/<domain>.sh` | `ab.<domain>` 或 `ab.<domain>.*` | `_ab.<domain>.*` | 单文件领域（如 `src/dev/git.sh` → `ab.git.*`） |
| `src/<cat>/<domain>/*.sh` | `ab.<domain>` 或 `ab.<domain>.*` | `_ab.<domain>.*` | 多文件领域（如 `src/fzf/fs/*.sh` → `ab.fs.*`） |

## 4. 函数写法与防泄露约束

1. **统一声明语法**：一律使用 `function ab.xxx {` / `function _ab.xxx {`。禁止 `foo() {` 和 `foo() (`（避免与已有 alias 展开冲突，保证解析器与 lint 规则唯一）。
2. **禁止全局变量泄露**：
   - 禁止在脚本顶层定义裸变量（需要路径/常量请放函数内 `local` 或通过私有 helper 返回）。
   - 函数体内所有局部变量（包括 `for` / `while read` 循环变量）必须声明 `local`。
3. **Subshell 隔离原则**：
   - `_utils/` 与普通工具函数不套 subshell（避免无谓 `fork` 与跨 shell `return` 坑）。
   - 仅当函数需要改变进程级状态且不想影响父 shell（如 `cd` 后不恢复、`umask 077`）时，在 `function ab.xxx {` 内部局部包一层 `( ... )`（如 `ab.tmux.prune`、`ab.codex`）。
4. **`src/` 内零 `alias`**：所有短命令别名（`fs/fj/fe/fh/cs/cj/ce`、`oc/oc.fc/np/ab.ca`）统一放在各环境的 `.zsh.alias` 中维护；`src/` 内部函数相互调用一律使用规范名（如 `ab.clip.last` 调 `ab.clip`，不调 `oc`）。
5. **纯 Shell 约束**：`albert-scripts/` 内不引入 Python 等额外解释器脚本，只使用 POSIX `awk` / `sed` / 常见 CLI（`fzf` / `fd` / `bat`）。

## 5. 元注释规范（注释即索引）

每个公开函数**紧贴上方**必须写元注释块（不能隔空行），`ab` 与 `ab.lint` 直接从源码解析：

```bash
# @desc: 通过 OSC 52 将标准输入写入本地剪贴板（必填）
# @usage: cmd | ab.clip（选填；带参数命令请以函数名开头，如 ab.codex [off|<query>]）
# @alias: oc（选填；空格分隔，仅填写 .zsh.alias 中存在的 1:1 短别名）
# @tags: clipboard osc52（选填；空格分隔，补充搜索关键词）
function ab.clip {
  ...
}
```

- `@desc` **必填**，漏写会导致 `ab.lint` 失败。
- `@usage` 若以 `<函数名> ` 开头，`ab` 选中后通过 `Enter` 放进 zsh 命令行缓冲区时会自动补一个尾随空格方便继续输参数；管道/无参命令不补空格。

## 6. `ab` 检索器与 `ab.lint` 校验

全部实现在单文件 `src/meta/ab.sh` 中（纯 Shell + POSIX `awk`）：

- **`ab [query]`**：打开 fzf 交互面板检索全部公开命令（可按命令名、分类 `[dev]`、`@alias`、`@tags`、`@desc` 过滤），右侧预览元信息与 `bat` 高亮源码（无 `bat` 时自动降级纯文本行号预览）。
  - `Enter`：zsh 下用 `print -z` 放入命令行缓冲区（bash 下打印到标准输出）。
  - `Ctrl-X`：写入历史并立即执行。
  - `Ctrl-E`：用 `${FS_EDITOR:-nvim}` 直接跳转到对应源文件定义行。
- **`ab.lint`**：静态检查以下 5 项，不通过返回非 0：
  1. `src/` 内不允许出现 `alias`；
  2. 所有函数必须用 `function <name> {` 声明；
  3. 函数名严格匹配两层约定式路由；
  4. 全仓不允许重名函数；
  5. 所有公开函数必须有 `# @desc:`。

## 7. 新增 / 修改命令 Checklist

1. 按功能放进 `src/<category>/<domain>.sh`（文件过大时拆成 `src/<category>/<domain>/*.sh`，共享私有函数放 `_common.sh`）。
2. 使用 `function ab.<domain>.<action> {`（私有 helper 用 `_ab.<domain>.*`），函数内变量全部 `local`。
3. 函数上方补齐 `# @desc:`（必要时补 `@usage` / `@alias` / `@tags`）。
4. 如需短别名，同步添加到对应 `.zsh.alias`。
5. 运行 `ab.lint` 确认 `0 violations`，并执行 `source ~/.albert-scripts/export.sh` 验证加载正常。
