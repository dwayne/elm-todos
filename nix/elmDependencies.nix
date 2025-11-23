{ fetchElmPackage }:
#
# elmLock :: [{ author: String, package: String, version: Version, sha256: SHA256 }]
#
# where
#
# Version is a String with format MAJOR.MINOR.PATCH
#
elmLock: map (input: input // { drv = fetchElmPackage input; }) elmLock
