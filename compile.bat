set ENGINE_DIR=%1
set OUT_DIR=%2
set PLATFORM=%3
set NDK_PATH=%4
set ANDROID_VER=%5

IF "%PLATFORM%" == "android" (
aapt2 compile --dir res -o %OUT_DIR%/res.zip
aapt2 link -o %OUT_DIR%/output.apk -I %NDK_PATH%/platforms/android-%ANDROID_VER%/android.jar %OUT_DIR%/res.zip --java . --manifest %ENGINE_DIR%/AndroidManifest.xml
%ENGINE_DIR%/zip -r %OUT_DIR%/output.apk lib/
%ENGINE_DIR%/zip -r %OUT_DIR%/output.apk assets/
zipalign -p -f -v 4 %OUT_DIR%/output.apk %OUT_DIR%/unsigned.apk
apksigner sign --ks %ENGINE_DIR%/debug.keystore --ks-pass pass:android --out %OUT_DIR%/signed.apk %OUT_DIR%/unsigned.apk
)


:: shader compile
glslc %ENGINE_DIR%/shader.vert -o assets/vert.spv
glslc %ENGINE_DIR%/shader.frag -o assets/frag.spv
::