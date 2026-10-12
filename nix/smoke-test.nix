{
  runCommand,
  nodejs,
  qpdf-wasm,
  libqpdf-wasm,
}:

runCommand "qpdf-wasm-smoke-test"
  {
    nativeBuildInputs = [ nodejs ];
    EXPECTED_QPDF_VERSION = libqpdf-wasm.version;
  }
  ''
    tar xzf ${qpdf-wasm}/*.tgz
    cd package
    node ${./smoke-test.js}
    touch $out
  ''
