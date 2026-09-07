{
  description = "Linux common command-line tools";

  inputs = {
    # 基线档：清单里不带 fast. 前缀的软件使用这条来源。
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # 快变档：直接跟踪 master，优先获得新版，可能需要本地构建。
    nixpkgs-fast.url = "github:NixOS/nixpkgs/master";
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
