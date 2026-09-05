{
  description = "Linux common command-line tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.tools = pkgs.buildEnv {
        name = "common-tools";
        paths = import ./packages.nix pkgs;
      };
    };
}
