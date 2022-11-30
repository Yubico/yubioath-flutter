#!/bin/bash -x

GITHUB_REF=`git branch --show-current`
if [ $# -gt 0 ] ; then
   GITHUB_REF="$1"
fi

export REF=$(echo ${GITHUB_REF} | cut -d '/' -f 3,4,5,6,7 | sed -r 's/\//_/g')
export FLUTTER_APK=build/app/outputs/flutter-apk
export NATIVE_LIBS=build/app/intermediates/merged_native_libs/release/out/lib

rm -rf artifacts
mkdir artifacts
cp "${FLUTTER_APK}/app-arm64-v8a-release.apk"   artifacts/yubico-authenticator-arm64-v8a-${REF}.apk
cp "${FLUTTER_APK}/app-armeabi-v7a-release.apk" artifacts/yubico-authenticator-armeabi-v7a-${REF}.apk
cp "${FLUTTER_APK}/app-x86_64-release.apk"      artifacts/yubico-authenticator-x86_64-${REF}.apk
cp "${FLUTTER_APK}/app-release.apk"             artifacts/yubico-authenticator-${REF}.apk

cp build/app/outputs/mapping/release/mapping.txt artifacts/

pushd "${NATIVE_LIBS}/"
zip -r sym-arm64-v8a.zip arm64-v8a/*so
zip -r sym-armeabi-v7a.zip armeabi-v7a/*so
zip -r sym-x86_64.zip x86_64/*so
popd
cp "${NATIVE_LIBS}/"*zip artifacts/
