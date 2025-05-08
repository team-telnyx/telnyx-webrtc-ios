<!-- Ticket details and link -->
[WEBRTC-XXX - Ticket title](https://telnyx.atlassian.net/browse/WEBRTC-XXX)
---
<!-- Describe your change here -->
Please provide a summary of the change / issue with a proper context.

## :older_man: :baby: Behaviors
### Before changes
- Describe the behaviour before making the changes.

### After changes
- Describe the behaviour and impact after the changes.

## TODO
Please mention pending items if any.

## ✋ Manual testing
1. Please list down all the steps required to test the changes.

## Known Issues
Please mention known issues if any.

## Screenshots
Please attach the screenshots if required


## 🔄 iOS Regression Process

### General Guidelines
- **SDK Release**: Follow all the steps listed on `Application Flow Checklist`.
- **Mobile App Release**: Run all the tests listed on `Application Flow Checklist`
- **Bugfixes or Demo App Changes**: Only include the tests relevant to the implemented changes.

### Release Process for the Demo App
1. Create a release branch for the demo app only.
2. Update the version.
3. Run all tests from `Application Flow Checklist`
4. Merge the PR.
5. Create a tag under release/sample-app/VERSION
6. Release app to the store.

### Release Process for the SDK
1. Create a release branch by running the pipeline:
   [Create Pull Request Pipeline](https://github.com/team-telnyx/telnyx-webrtc-ios/actions/workflows/release_01_create_pull_request.yml).
   This will generate a branch named `release/RELEASE-X.X.X`.
2. Check out the release branch and update the changelog and documentation.
3. Run all tests from `Application Flow Checklist`
4. If errors are found:
   - Create a Jira ticket, resolve the issue, and create a PR to the release branch.
   - Execute the tests associated with the fix (run the failing test case).
5. If all tests pass, merge the release branch.
6. Run the pipeline:
   [Create GitHub Release Pipeline](https://github.com/team-telnyx/telnyx-webrtc-ios/actions/workflows/release_02_create_gh_release.yml) to create the release on GitHub.
7. Run the pipeline:
   [Deploy to CocoaPods Pipeline](https://github.com/team-telnyx/telnyx-webrtc-ios/actions/workflows/release_03_deploy_cocoapods.yml) to publish the release to CocoaPods.

---

## Application Flow Checklist

### 🧪 Logged in with Token

- [ ] **Connection:** Establish connection via Token

#### Inbound Calls (Receiving as Token user)
- [ ] Receive inbound call from SIP Connection
  - [ ] On WiFi
  - [ ] On Mobile Network

#### Outbound Calls (Making calls as Token user)
- [ ] Make outbound call to SIP Connection
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Make outbound call to associated number
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Make outbound call to PSTN
  - [ ] On WiFi
  - [ ] On Mobile Network

#### Notifications (While logged in as Token)
- [ ] Receive push notification (App Background) -> Reject Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Background) -> Accept Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Terminated) -> Reject Call
  - [ ] Screen On 
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Terminated) -> Accept Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)

---

### 📞 Logged in with SIP Connection

- [ ] **Connection:** Establish connection via SIP Credential

#### Inbound Calls (Receiving as SIP user)
- [ ] Receive inbound call from another SIP Connection
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Receive inbound call via associated number
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Receive inbound call from PSTN
  - [ ] On WiFi
  - [ ] On Mobile Network

#### Outbound Calls (Making calls as SIP user)
- [ ] Make outbound call to SIP Connection
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Make outbound call to associated number
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Make outbound call to PSTN
  - [ ] On WiFi
  - [ ] On Mobile Network

#### Notifications (While logged in as SIP)
- [ ] Receive push notification (App Background) -> Reject Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Background) -> Accept Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Terminated) -> Reject Call
  - [ ] Screen On 
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Terminated) -> Accept Call
  - [ ] Screen On 
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)

---

### 👤 Logged in with genCred

- [ ] **Connection:** Establish connection via genCred 

#### Inbound Calls (Receiving as genCred user)
- [ ] Receive inbound call from SIP Connection
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Receive inbound call via associated number
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Receive inbound call from PSTN
  - [ ] On WiFi
  - [ ] On Mobile Network

#### Outbound Calls (Making calls as genCred user)
- [ ] Make outbound call to SIP Connection
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Make outbound call to associated number
  - [ ] On WiFi
  - [ ] On Mobile Network
- [ ] Make outbound call to PSTN
  - [ ] On WiFi
  - [ ] On Mobile Network

#### Notifications (While logged in as genCred)
- [ ] Receive push notification (App Background) -> Reject Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Background) -> Accept Call
  - [ ] Screen On
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Terminated) -> Reject Call
  - [ ] Screen On 
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)
- [ ] Receive push notification (App Terminated) -> Accept Call
  - [ ] Screen On 
  - [ ] Screen Locked (Active)
  - [ ] Screen Locked (Sleep)

---

### 🔁 General Reconnection Scenarios
- [ ] Establish call -> Drop network -> Re-establish connection within timeframe
  - [ ] On WiFi
  - [ ] On 4G/Mobile Network
- [ ] Establish call -> Drop network -> Fail to re-establish connection within timeframe (verify dropped state)
  - [ ] On WiFi
  - [ ] On 4G/Mobile Network

---

### 📊 General Stats Scenarios
- [ ] Enable stats (config level) -> Establish call -> Verify portal stats appear
- [ ] Disable stats (config level) -> Establish call -> Verify no portal stats appear
- [ ] Enable stats (call level) -> Establish call -> Verify quality metrics are available
- [ ] Disable stats (call level) -> Establish call -> Verify quality metrics are not available