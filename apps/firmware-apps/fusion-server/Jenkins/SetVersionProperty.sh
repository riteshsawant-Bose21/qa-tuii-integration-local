VersionFile='../fusion/VERSION'
VERSION_MAJOR=$(grep MAJOR $VersionFile | cut -d' ' -f 3)
VERSION_MINOR=$(grep MINOR $VersionFile | cut -d' ' -f 3)
VERSION_PATCH=$(grep PATCH $VersionFile | cut -d' ' -f 3)
sversion=$(printf "%d.%d.%d" $VERSION_MAJOR $VERSION_MINOR $VERSION_PATCH)
version=$(printf "%d.%d.%d-%d+%s" $VERSION_MAJOR $VERSION_MINOR $VERSION_PATCH $buildNumber $gitHashShort)
versionAWS=$(printf "%d.%d.%d-%d-%s" $VERSION_MAJOR $VERSION_MINOR $VERSION_PATCH $buildNumber $gitHashShort)

echo $sversion
