# This script updates the SDK version in the required files
# Example of usage: sh scripts/setup_version.sh -v "1.0.0"
#!/bin/bash
while getopts v: flag
do
    case "${flag}" in
        v) version=${OPTARG};;
    esac
done
echo "New version: $version";

# Replace version in podspec file
sed -i '' 's/spec.version = .*/spec.version = "'$version'"/' TelnyxRTC.podspec
# Replace version in info.plist file
sed -i '' 's/MARKETING_VERSION = .*/MARKETING_VERSION = '"$version"';/' TelnyxRTC.xcodeproj/project.pbxproj
# Replace SDK_VERSION in Message.swift
sed -i '' 's/internal static let SDK_VERSION = .*/internal static let SDK_VERSION = "'$version'"/' TelnyxRTC/Telnyx/Verto/Message.swift
