{
  lib,
  buildNpmPackage,
  importNpmLock,
  src,
  pkg-config,
  emscriptenCacheHook,
  libjpeg-turbo-wasm,
  zlib-wasm,
  libqpdf-wasm,
}:

let
  packageJson = lib.importJSON (src + "/package.json");
in
buildNpmPackage {
  pname = "qpdf-wasm";
  inherit (packageJson) version;

  inherit src;
  npmDeps = importNpmLock { npmRoot = src; };
  npmConfigHook = importNpmLock.npmConfigHook;

  nativeBuildInputs = [
    pkg-config
    emscriptenCacheHook
  ];
  buildInputs = [
    libjpeg-turbo-wasm
    zlib-wasm
    libqpdf-wasm
  ];

  dontNpmBuild = true;

  buildPhase = ''
    runHook preBuild
    em++ -o qpdf.js \
      $(pkg-config --static --cflags --libs libqpdf) \
      -Wl,--gc-sections \
      --no-entry \
      -sEXPORTED_RUNTIME_METHODS=HEAPU8,UTF8ToString \
      -sEXPORTED_FUNCTIONS=_qpdf_init,_qpdf_get_qpdf_version,_qpdf_cleanup,_qpdf_has_error,_qpdf_get_error,_qpdf_get_error_full_text,_qpdf_get_error_code,_qpdf_get_error_filename,_qpdf_get_error_file_position,_qpdf_get_error_message_detail,_qpdf_check_pdf,_qpdf_read_memory,_qpdf_init_write_memory,_qpdf_write,_qpdf_get_buffer_length,_qpdf_get_buffer,_qpdf_set_preserve_encryption,_malloc,_free \
      -sMAXIMUM_MEMORY=67108864 \
      -sALLOW_MEMORY_GROWTH \
      -sENVIRONMENT=node \
      -sFILESYSTEM=0 \
      -sNO_DISABLE_EXCEPTION_CATCHING \
      -sMODULARIZE
    node_modules/.bin/tsc --build ./tsconfig.json
    cp qpdf.js qpdf.wasm qpdf.d.ts dist/
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    npm pack --cache "$NIX_BUILD_TOP/npm-cache" --pack-destination $out
    runHook postInstall
  '';
}
