
#!/bin/sh -e

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
#trap 'rm -f "$xcconfig"' INT TREM HUP EXIT

echo "LD = $PWD/ld.py" >> $xcconfig
echo "DEBUG_INFORMATION_FORMAT = dwarf" >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"

cd "$PWD/../"
carthage bootstrap "$@"
