#!/bin/bash

#set -eu

mkdir build || true

echo "[1] Build wasm"
wasmPayloadFile=$(mktemp)
#trap 'rm -f $wasmPayloadFile' ERR EXIT
GOOS=js GOARCH=wasm go build -ldflags="-s -w" -o "$wasmPayloadFile" -mod=vendor wasm/wasm.go

echo "[2] Pack wasm into javascript"
cp "$(go env GOROOT)/misc/wasm/wasm_exec.js" frontend/js/wasm_exec.js

wasmJsPayloadFile="frontend/js/wasmPayload.base64"
rm $wasmJsPayloadFile || true
echo -n 'const wasmPayloadInlineURL = `data:application/wasm;base64, ' > "${wasmJsPayloadFile}"
base64 "$wasmPayloadFile" >> "${wasmJsPayloadFile}"
echo '`' >> "${wasmJsPayloadFile}"
JsPayloadConcatenatedFile="frontend/js/jsPayloads.js"
rm $JsPayloadConcatenatedFile || true
cat frontend/js/*.js > "${JsPayloadConcatenatedFile}"
cat "${wasmJsPayloadFile}" >> "${JsPayloadConcatenatedFile}"

echo "[3] Pack css & javascript into a single HTML file"
mkdir -p build
htmlTemplate="frontend/index.template.html"
CSSPayloadFile="frontend/css/style.css"
sed -i -e "/INLINE_WASM_PLACEHOLDER/r $JsPayloadConcatenatedFile" -e "/INLINE_WASM_PLACEHOLDER/d" "${htmlTemplate}"
sed -e "/INLINE_STYLE_PLACEHOLDER/r $CSSPayloadFile" -e "/INLINE_STYLE_PLACEHOLDER/d" "${htmlTemplate}" > build/index.html

echo "[4] Done. You can upload the build folder to your server or use it locally"
