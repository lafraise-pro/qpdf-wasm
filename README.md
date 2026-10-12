# @lafraise/qpdf

A WebAssembly build of libqpdf for Node.

## Build

```sh
nix build            # result/lafraise-qpdf-<version>.tgz
nix flake check      # builds the tarball and runs nix/smoke-test.js against it
npm publish result/lafraise-qpdf-*.tgz
```

The flake builds zlib, libjpeg-turbo and libqpdf from the submodules with
nixpkgs' emscripten, links `qpdf.wasm`, compiles `index.ts` and packs the
result with `npm pack`. `build.sh` is the same pipeline against a local emsdk;
`nix develop` provides its tools.
