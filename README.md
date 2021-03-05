# webrtc-ios-sdk

Enable Telnyx real-time communication services on iOS.

## Project structure: 

- SDK project: Enable Telnyx WebRTC communications.
- SDK Tests project.
- Demo app project. 


## Project Setup:

1. Clone the repository
2. Run the command `pod install` to install de dependencies inside the project root folder. 
3. Open the Workspace : `WebRTCSDK.xcworkspace`
4. You will find 3 targets to build: 
      - The SDK
      - The SDK Tests
      - The Demo App
      
<p align="center">
<img width="418" align="center"  alt="Screen Shot 2021-03-03 at 09 58 45" src="https://user-images.githubusercontent.com/75636882/109809493-1bec0500-7c07-11eb-81a1-92323d508554.png">
</p>

5. Select the target `WebRTCSDK (WebRTCSDK Project)` to build the SDK
6. Select the target `WebRTCSDKTests` to run the tests: For this you will need to long press over the Run button and select `Build for testing`

<p align="center">
<img width="153" align="center" alt="Screen Shot 2021-03-03 at 10 04 05" src="https://user-images.githubusercontent.com/75636882/109810077-d4b24400-7c07-11eb-91ec-d81e72ae9069.png">
</p>

7.  Select target `TelnyxWebRTCDemo` to run the demo app. The SDK should be manually builded in order to get the app running (Step 5)
8. Enjoy 😎






-----


Questions? Comments? Building something rad? [Join our Slack channel](https://joinslack.telnyx.com/) and share.

## License

[`MIT Licence`](./LICENSE) © [Telnyx](https://github.com/team-telnyx)
