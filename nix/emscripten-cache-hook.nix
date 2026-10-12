{ makeSetupHook, emscripten }:

makeSetupHook {
  name = "emscripten-cache-hook";
  propagatedBuildInputs = [ emscripten ];
  substitutions = {
    emscripten_cache = "${emscripten}/share/emscripten/cache";
  };
} ./emscripten-cache-hook.sh
