{
  description = "@lafraise/qpdf: a WebAssembly build of libqpdf";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    self.submodules = true;
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          emscriptenCacheHook = pkgs.callPackage ./nix/emscripten-cache-hook.nix { };
          libjpeg-turbo-wasm = pkgs.callPackage ./nix/libjpeg-turbo.nix {
            inherit emscriptenCacheHook;
            src = ./libjpeg-turbo;
          };
          zlib-wasm = pkgs.callPackage ./nix/zlib.nix {
            inherit emscriptenCacheHook;
            src = ./zlib;
          };
          libqpdf-wasm = pkgs.callPackage ./nix/libqpdf.nix {
            inherit emscriptenCacheHook libjpeg-turbo-wasm zlib-wasm;
            src = ./qpdf;
          };
          qpdf-wasm = pkgs.callPackage ./nix/qpdf-wasm.nix {
            inherit
              emscriptenCacheHook
              libjpeg-turbo-wasm
              zlib-wasm
              libqpdf-wasm
              ;
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./index.ts
                ./qpdf.d.ts
                ./tsconfig.json
                ./package.json
                ./package-lock.json
                ./LICENSE.md
                ./NOTICE.md
                ./COPYRIGHT.md
              ];
            };
          };
        in
        {
          inherit
            libjpeg-turbo-wasm
            zlib-wasm
            libqpdf-wasm
            qpdf-wasm
            ;
          default = qpdf-wasm;
        }
      );

      checks = forAllSystems (pkgs: {
        smoke-test = pkgs.callPackage ./nix/smoke-test.nix {
          inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) qpdf-wasm libqpdf-wasm;
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            emscripten
            cmake
            pkg-config
            nodejs
          ];
        };
      });
    };
}
