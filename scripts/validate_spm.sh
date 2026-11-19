#!/bin/bash
# Validate the distributable manifest, independently of the demo/Xcode project.
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
validation_dir=$(mktemp -d "${TMPDIR:-/tmp}/telnyx-spm.XXXXXX")
trap 'rm -rf "$validation_dir"' EXIT
cp "$repo_root/Package.swift" "$validation_dir/"
cp -R "$repo_root/TelnyxRTC" "$validation_dir/TelnyxRTC"
cd "$validation_dir"
xcrun swift package dump-package > /dev/null
xcodebuild -resolvePackageDependencies -scheme telnyx-webrtc-ios
xcodebuild -scheme telnyx-webrtc-ios -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
