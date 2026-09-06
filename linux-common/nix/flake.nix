{
  description = "Linux common command-line tools";

  # 两条来源都指向 nixpkgs-unstable，但各自独立锁定一个 rev。
  # 独立更新的能力来自"来源有两条"，不来自分支不同。
  inputs = {
    # 基线档：清单里不带 fast. 前缀的软件使用这条来源。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # 快变档：清单里带 fast. 前缀的软件使用这条来源。
    nixpkgs-fast.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, nixpkgs-fast, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            fast = import nixpkgs-fast { inherit system; };
          })
        ];
      };
    in
    {
      packages.${system}.tools = pkgs.buildEnv {
        name = "common-tools";
        paths = import ./packages.nix pkgs;
      };
    };
}
