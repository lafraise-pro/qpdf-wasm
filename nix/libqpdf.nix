{
  stdenv,
  src,
  cmake,
  pkg-config,
  emscriptenCacheHook,
  libjpeg-turbo-wasm,
  zlib-wasm,
}:

stdenv.mkDerivation {
  pname = "libqpdf-wasm";
  version = "12.2.0";

  inherit src;
  patches = [ ../qpdf.patch ];

  nativeBuildInputs = [
    cmake
    pkg-config
    emscriptenCacheHook
  ];
  buildInputs = [
    libjpeg-turbo-wasm
    zlib-wasm
  ];

  dontUseCmakeConfigure = true;
  dontStrip = true;

  # Emscripten's toolchain file only searches CMAKE_FIND_ROOT_PATH.
  configurePhase = ''
    runHook preConfigure
    emcmake cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=MinSizeRel \
      -DCMAKE_INSTALL_PREFIX=$out \
      -DCMAKE_FIND_ROOT_PATH="${libjpeg-turbo-wasm};${zlib-wasm}" \
      -DBUILD_SHARED_LIBS=OFF \
      -DINSTALL_EXAMPLES=OFF \
      -DCMAKE_CXX_FLAGS='-Os -fdata-sections -ffunction-sections' \
      -DREQUIRE_CRYPTO_NATIVE=ON \
      -DUSE_IMPLICIT_CRYPTO=OFF
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --parallel $NIX_BUILD_CORES --target libqpdf
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/lib build/libqpdf/libqpdf.a
    install -Dm644 -t $out/lib/pkgconfig build/libqpdf/libqpdf.pc
    runHook postInstall
  '';
}
