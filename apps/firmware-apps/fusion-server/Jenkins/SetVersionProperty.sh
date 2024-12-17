cd $buildDir
VERSION_MAJOR=$(cat $VersionFile | grep MAJOR | awk -F" " '{print $3}' | tr -d '\r' | tr -d '\n')
VERSION_MINOR=$(cat $VersionFile | grep MINOR | awk -F" " '{print $3}' | tr -d '\r' | tr -d '\n')
VERSION_PATCH=$(cat $VersionFile | grep PATCH | awk -F" " '{print $3}' | tr -d '\r' | tr -d '\n')
sversion=$(printf "%d.%d.%d" $VERSION_MAJOR $VERSION_MINOR $VERSION_PATCH)
version=$(printf "%d.%d.%d-%d+%s" $VERSION_MAJOR $VERSION_MINOR $VERSION_PATCH $buildNumber $gitHashShort)
versionAWS=$(printf "%d.%d.%d-%d-%s" $VERSION_MAJOR $VERSION_MINOR $VERSION_PATCH $buildNumber $gitHashShort)

echo $version
