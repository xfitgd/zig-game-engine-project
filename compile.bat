IF "%2" == "android" (
aapt2 compile --dir res -o %1/res.zip
aapt2 link -o %1/output.apk -I %3/platforms/android-%4/android.jar %1/res.zip --java . --manifest zig-game-engine-project/AndroidManifest.xml
zip -r %1/output.apk lib/
zip -r %1/output.apk assets/
zipalign -p -f -v 4 %1/output.apk %1/unsigned.apk
apksigner sign --ks zig-game-engine-project/debug.keystore --ks-pass pass:android --out %1/signed.apk %1/unsigned.apk
)

zig-game-engine-project/shader_compile