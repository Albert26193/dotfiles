# Nix 软件清单实践

适用于 x86_64 Linux。`flake.nix` 定义依赖和入口，`packages.nix` 定义软件清单，
首次运行 `nix flake lock` 生成 `flake.lock`。将这三个文件一起保存到 Git，供以后重放。
ARM64 Linux 需要将 `flake.nix` 中的 `system` 改成 `aarch64-linux`。

## 1. 安装并加载 Nix

在仓库根目录执行；如果已安装 Nix，可直接加载环境并查看版本。

```bash
bash linux-common/init-scripts/install_nix.sh
source "$HOME/.nix-profile/etc/profile.d/nix.sh"
nix --version
```

看到 Nix 版本后再继续。如果安装报错，先解决报错。
安装脚本只安装包管理器，下面的步骤才会安装清单里的软件。

## 2. 启用 Flakes

打开 `${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf`，保留已有内容，添加：

```ini
extra-experimental-features = nix-command flakes
```

如果已有同名设置，把这两个值加入原有设置，不要重复添加同名行。

## 3. 生成锁文件

从仓库根目录进入配置目录：

```bash
cd linux-common/nix
nix flake lock path:.
cat flake.lock
```

`path:.` 明确读取当前目录，因此初次练习不用先执行 `git add`。
`tools` 对应 `flake.nix` 中的输出名称。
生成锁文件时可能下载 Nixpkgs 源码树，但不会安装清单中的软件。
锁文件的 `locked.rev` 是固定的 Nixpkgs 提交，后续重放应保留它。

如需先验证能否构建，可选执行 `nix build 'path:.#tools' --no-link`。
下一步的 `nix profile add` 会自动准备软件环境，不必提前单独构建。

## 4. 安装清单

仍在 `linux-common/nix` 目录执行：

```bash
nix profile add 'path:.#tools'
nix profile list
"$HOME/.nix-profile/bin/git" --version
"$HOME/.nix-profile/bin/tmux" -V
"$HOME/.nix-profile/bin/rg" --version
```

本教程按本机 Nix 2.35.2 使用 `add`；旧名称 `install` 已弃用，会产生警告。
显式使用 profile 路径，确认运行的是刚安装的工具；机器上可能已有其他来源的同名命令。
`nix profile list` 通常将本地输出显示为 `tools`；以下命令中的 `tools` 应以实际显示的 `Name` 为准。
profile 中这套环境作为一个条目出现，不会逐个列出清单里的软件。

## 5. 亲手增加和删除软件

在 `packages.nix` 的列表里加一行 `pkgs.hello`，保存后执行：

```bash
nix profile upgrade tools
"$HOME/.nix-profile/bin/hello"
```

应该输出 `Hello, world!`。然后删除 `pkgs.hello` 那一行，再执行：

```bash
nix profile upgrade tools
test ! -e "$HOME/.nix-profile/bin/hello" && echo 'hello 已从当前环境移除'
```

这会替换整套环境。其他方式单独安装的 hello 不受影响；旧环境可能仍保留在 Nix store 中供回滚。
增加或删除清单项不需要更新锁文件。

## 6. 升级版本与换机器重放

主动升级 Nixpkgs 中的软件版本：

```bash
nix flake update --flake path:.
nix profile upgrade tools
git diff -- flake.lock
```

确认版本合适后，将 `flake.nix`、`packages.nix` 和生成的 `flake.lock` 一起提交。

在另一台相同架构的 Linux 上安装 Nix、启用 Flakes、取得这三个文件，进入配置目录后执行：

```bash
nix profile add 'path:.#tools' --no-update-lock-file
```

重放时不要运行 `nix flake update`，这样才能沿用原先锁定的依赖版本。

参考：[锁文件](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake-lock.html)、
[更新 profile](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-profile-upgrade.html)。
