# Requirements:
# bundletool - https://github.com/google/bundletool/releases
# apktool - https://github.com/iBotPeaches/Apktool/releases
# uber-apk-signer - https://github.com/patrickfav/uber-apk-signer/releases

tools_path="$HOME/etc"
# update "tools_path" to the actual path to the catalog with tools
bundletool_path="$tools_path/bundletool-all-1.4.0.jar"
apktool_path="$tools_path/apktool_2.5.0.jar"
apk_signer_path="$tools_path/uber-apk-signer-1.2.1.jar"

FILE_DIR=$(cd $(dirname $1) && pwd)
cd $FILE_DIR
FILE_EXT=${1##*.}
FILE_NAME=$(basename $1 ".$FILE_EXT")

if [[ $FILE_EXT = "aab" ]]; then
    echo "*** Extracting APKS from AAB"
    java -jar $bundletool_path build-apks --bundle=$FILE_NAME.$FILE_EXT --output=$FILE_NAME.apks --mode=universal

    echo "*** Extracting APK from APKS and moving it"
    unzip $FILE_NAME.apks -d $FILE_NAME
    mv "$FILE_NAME/universal.apk" "$FILE_NAME.apk"

    echo "*** Removing .apks file and catalog"
    rm "$FILE_NAME.apks"
    rm -rf $FILE_NAME
elif [[ $FILE_EXT != "apk" ]]; then
    echo "*** Unknown file extension"
    exit 1
fi

DECOMPILED_PATH="$FILE_DIR/$FILE_NAME.$FILE_EXT-decompiled"

echo "*** Decompiling the APK file"
java -jar $apktool_path d -o $DECOMPILED_PATH "$FILE_DIR/$FILE_NAME.apk"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" > network_security_config.xml
echo "<network-security-config>" >> network_security_config.xml
echo "    <base-config>" >> network_security_config.xml
echo "        <trust-anchors>" >> network_security_config.xml
echo "            <certificates src=\"system\" />" >> network_security_config.xml
echo "            <certificates src=\"user\" />" >> network_security_config.xml
echo "        </trust-anchors>" >> network_security_config.xml
echo "    </base-config>" >> network_security_config.xml
echo "    <domain-config cleartextTrafficPermitted=\"true\">" >> network_security_config.xml
echo "        <domain includeSubdomains=\"true\">127.0.0.1</domain>" >> network_security_config.xml
echo "    </domain-config>" >> network_security_config.xml
echo "</network-security-config>" >> network_security_config.xml
echo "*** Replacing @xml/network_security_config.xml"
mv network_security_config.xml "$DECOMPILED_PATH/res/xml/"

echo "*** Checking AndroidManifest"
SHOULD_PATCH=false
if [[ $(grep "android:networkSecurityConfig" "$DECOMPILED_PATH/AndroidManifest.xml") ]]; then
    echo "*** No need to patch AndroidManifest"
else
    echo "Patching AndroidManifest"
    sed -i "" -e "s#<application #<application android:networkSecurityConfig=\"@xml/network_security_config\" #" "$DECOMPILED_PATH/AndroidManifest.xml"
    SHOULD_PATCH=true
fi

echo "*** Building new APK file"
java -jar $apktool_path b $DECOMPILED_PATH --use-aapt2

echo "*** Signing APK file"
java -jar $apk_signer_path -a "$DECOMPILED_PATH/dist/$FILE_NAME.apk" --allowResign --overwrite

if [[ $SHOULD_PATCH == true ]]; then
    echo "*** Need to patch AndroidManifest!"
fi
echo "$DECOMPILED_PATH/dist/$FILE_NAME.apk" | pbcopy
echo "*** Output APK file $DECOMPILED_PATH/dist/$FILE_NAME.apk"
echo "*** The path was copied to the clipboard"
read -n 1 -p "Install via adb? (1 = yes / 0 = no)" INSTALL
if [[ $INSTALL == "1" ]]; then
    echo "\n"
    adb install "$DECOMPILED_PATH/dist/$FILE_NAME.apk"
fi