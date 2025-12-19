# Running UI Tests on Firebase Test Lab

This guide explains how to set up, build, and run UI Tests for the Telnyx WebRTC iOS Demo app on Firebase Test Lab.

<hr>

## Prerequisites

- Xcode installed on your macOS system
- CocoaPods installed
- Access to a Firebase project with Test Lab enabled
- Valid SIP credentials for testing

## Setup Instructions

### 1. Install Google Cloud CLI

Install the `gcloud` CLI tool locally by following the instructions at:
https://firebase.google.com/docs/test-lab/ios/command-line

### 2. Configure Firebase Project

Download the `GoogleService-Info.plist` file from your Firebase project.

### 3. Prevent Tracking Sensitive Files

Execute the following commands to prevent Git from tracking changes to sensitive files:

```sh
git update-index --assume-unchanged TelnyxWebRTCDemo/GoogleService-Info.plist
git update-index --assume-unchanged TelnyxWebRTCDemoUITests/TestConstants.swift
```

### 4. Replace Firebase Configuration

Replace the dummy `GoogleService-Info.plist` in the project with your downloaded file.

### 5. Install Dependencies

Run the following command to install all required dependencies:

```sh
pod install
```

### 6. Open Project

Open the Xcode workspace:

```sh
open TelnyxRTC.xcworkspace
```

### 7. Configure Test Credentials

Open the `TelnyxWebRTCDemoUITests/TestConstants.swift` file and replace the test variables with valid SIP credentials:

```swift
class TestConstants {

    private init() {}

    static let sipUser = "❬SIP_USER❭"
    static let sipPassword = "❬SIP_PASSWORD❭"
    static let token = "❬SIP_TOKEN❭"
    static let destinationNumber = "❬DESTINATION_NUMBER❭"

    static let callerNumber = "❬CALLER_NUMBER❭"
    static let callerName = "Telnyx WebRTC Test User"

}
```

### 8. Compile Tests

Compile the tests using the following command:

```sh
xcodebuild build-for-testing \
     -workspace TelnyxRTC.xcworkspace \
     -scheme TelnyxWebRTCDemo \
     -sdk iphoneos \
     -configuration Debug \
     -destination 'generic/platform=iOS' \
     -derivedDataPath build \
     SUPPORTS_MACCATALYST=NO
```

### 9. Prepare Test Package

Compress the `Debug-iphoneos` folder and the `.xctestrun` file located inside `build/Build/Products`:

```sh
cd build/Build/Products

zip -r TelnyxWebRTCDemoUITests.zip \
  Debug-iphoneos \
  TelnyxWebRTCDemo_iphoneos18.0.xctestrun
```

> **Note:** Replace `TelnyxWebRTCDemo_iphoneos18.0.xctestrun` with the actual file generated in your `build/Build/Products` directory. The filename may vary depending on your Xcode and iOS SDK versions.

### 10. Run Tests on Firebase Test Lab

Navigate back to the project root and run the tests on Firebase Test Lab:

```sh
cd ../../../

gcloud firebase test ios run \
  --test build/Build/Products/TelnyxWebRTCDemoUITests.zip \
  --device model=iphone14pro,version=16.6,locale=en_US,orientation=portrait
```

## Troubleshooting

- If you encounter authentication issues with Firebase, ensure you're logged in with the correct account using `gcloud auth login`
- For test failures, check the Firebase Test Lab console for detailed logs and screenshots
- Verify that your SIP credentials are valid and have the necessary permissions

## Additional Resources

- [Firebase Test Lab Documentation](https://firebase.google.com/docs/test-lab)
- [Xcode UI Testing Documentation](https://developer.apple.com/documentation/xctest/user_interface_tests)