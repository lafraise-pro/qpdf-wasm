{
  stdenv,
  src,
  cmake,
  emscriptenCacheHook,
}:

stdenv.mkDerivation {
  pname = "libjpeg-turbo-wasm";
  version = "unstable-2025-06-06";

  inherit src;
  patches = [ ../libjpeg-turbo.patch ];

  nativeBuildInputs = [
    cmake
    emscriptenCacheHook
  ];

  dontUseCmakeConfigure = true;
  dontStrip = true;

  configurePhase = ''
    runHook preConfigure
    emcmake cmake -S . -B build \
      -DCMAKE_INSTALL_PREFIX=$out \
      -DCMAKE_C_FLAGS='-Os -fdata-sections -ffunction-sections' \
      -DENABLE_STATIC=1 \
      -DENABLE_SHARED=0 \
      -DWITH_JAVA=0 \
      -DWITH_TURBOJPEG=0 \
      -DWITH_FUZZ=0
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --parallel $NIX_BUILD_CORES --target jpeg-static
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 -t $out/include build/jconfig.h src/jpeglib.h src/jerror.h src/jmorecfg.h
    install -Dm644 -t $out/lib build/libjpeg.a
    install -Dm644 -t $out/lib/pkgconfig build/pkgscripts/libjpeg.pc
    runHook postInstall
  '';
}
