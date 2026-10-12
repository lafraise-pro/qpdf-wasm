{
  stdenv,
  src,
  emscriptenCacheHook,
}:

stdenv.mkDerivation {
  pname = "zlib-wasm";
  version = "1.3.1";

  inherit src;

  nativeBuildInputs = [ emscriptenCacheHook ];

  dontStrip = true;

  configurePhase = ''
    runHook preConfigure
    emconfigure ./configure --static --prefix=$out
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    emmake make -j$NIX_BUILD_CORES libz.a
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    emmake make install
    runHook postInstall
  '';
}
