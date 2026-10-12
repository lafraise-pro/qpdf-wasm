#!/bin/bash
set -e

mkdir -p local/lib/pkgconfig
mkdir -p local/include
install_prefix="$(pwd)/local"

function build_libjpeg() {
    pushd libjpeg-turbo/
    git apply ../libjpeg-turbo.patch || true
    mkdir -p build
    cd build
    emmake cmake \
           -DCMAKE_INSTALL_PREFIX="$install_prefix" \
           -DCMAKE_C_FLAGS='-Os -fdata-sections -ffunction-sections' \
           -DENABLE_STATIC=1 \
           -DENABLE_SHARED=0 \
           -DWITH_JAVA=0 \
           -DWITH_TURBOJPEG=0 \
           -DWITH_FUZZ=0 \
           ..
    emmake make -j8 jpeg-static
    cp jconfig.h ../src/{jpeglib,jerror,jmorecfg}.h "$install_prefix/include/"
    cp libjpeg.a "$install_prefix/lib/"
    cp pkgscripts/libjpeg.pc "$install_prefix/lib/pkgconfig/"
    popd
}

function build_zlib() {
    pushd zlib
    emconfigure ./configure --prefix "$install_prefix"
    emmake make -j8 libz.a
    cp zconf.h zlib.h "$install_prefix/include/"
    cp libz.a "$install_prefix/lib/"
    cp zlib.pc "$install_prefix/lib/pkgconfig/"
    popd
}

function build_qpdf() {
    pushd qpdf
    git apply ../qpdf.patch || true
    emmake cmake -S . -B build \
           -DCMAKE_BUILD_TYPE=MinSizeRel \
           -DCMAKE_PREFIX_PATH="$install_prefix" \
           -DCMAKE_INSTALL_PREFIX="$install_prefix" \
           -DBUILD_SHARED_LIBS=OFF \
           -DINSTALL_EXAMPLES=OFF \
           -DCMAKE_CXX_FLAGS='-Os -fdata-sections -ffunction-sections -I../zlib -L../zlib' \
           -DREQUIRE_CRYPTO_NATIVE=ON \
           -DUSE_IMPLICIT_CRYPTO=OFF
    emmake cmake --build build --parallel --target libqpdf
    cp build/libqpdf/libqpdf.a "$install_prefix/lib/"
    cp build/libqpdf/libqpdf.pc "$install_prefix/lib/pkgconfig/"
    popd
}

function build_wasm() {
    emcc -o qpdf.js \
         $(PKG_CONFIG_PATH="$install_prefix/lib/pkgconfig" pkg-config --env-only --static --cflags --libs libqpdf) \
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
}

function build_node_module() {
    npx --package=typescript tsc --build ./tsconfig.json
    cp --reflink=auto ./qpdf.js ./qpdf.wasm ./qpdf.d.ts dist/
}

build_libjpeg
build_zlib
build_qpdf
build_wasm
build_node_module
