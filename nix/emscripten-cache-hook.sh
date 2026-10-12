# emcc writes freshly built system libraries into EM_CACHE, and the
# store copy is read-only, so each build starts from a writable copy.
# emconfigure, emcmake and emmake replace PKG_CONFIG_PATH with
# EM_PKG_CONFIG_PATH.
setupEmscriptenCache() {
    local cache="$NIX_BUILD_TOP/emscripten-cache"
    cp -r @emscripten_cache@ "$cache"
    chmod -R u+w "$cache"
    export EM_CACHE="$cache"
    export EM_PKG_CONFIG_PATH="${PKG_CONFIG_PATH-}"
}

preConfigureHooks+=(setupEmscriptenCache)
