# Pre-call Diagnosis Feature

The Pre-call Diagnosis feature allows you to test call quality before making an actual call. This feature makes a short test call to collect network and audio quality metrics, providing insights into expected call performance.

## Overview

The Pre-call Diagnosis feature includes:

- **MOS (Mean Opinion Score)**: Overall call quality rating (1.0-5.0)
- **Call Quality**: Categorical quality assessment (excellent, good, fair, poor, unknown)
- **Jitter Metrics**: Network jitter statistics (min, max, average)
- **RTT Metrics**: Round-trip time statistics (min, max, average)
- **Packet Statistics**: Bytes and packets sent/received
- **ICE Candidates**: Network connectivity information

## Usage

### Basic Implementation

```swift
import TelnyxRTC

class MyViewController: UIViewController, TxClientDelegate {
    private var txClient: TxClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTelnyxClient()
    }
    
    private func setupTelnyxClient() {
        txClient = TxClient()
        txClient?.delegate = self
        
        // Configure and connect your client
        let config = TxConfig(/* your configuration */)
        try? txClient?.connect(txConfig: config)
    }
    
    private func runPreCallDiagnosis() {
        guard let client = txClient else { return }
        
        do {
            try client.startPreCallDiagnosis(
                testNumber: "+18005551234",    // Your test number
                callerName: "Pre-call Test",   // Optional caller name
                callerNumber: "+15551234567",  // Optional caller number
                duration: 10.0                 // Test duration in seconds
            )
        } catch {
            print("Failed to start diagnosis: \(error)")
        }
    }
    
    // MARK: - TxClientDelegate
    
    func onPreCallDiagnosisStateUpdated(state: PreCallDiagnosisState) {
        switch state {
        case .started:
            print("Diagnosis started...")
            
        case .completed(let diagnosis):
            handleDiagnosisResults(diagnosis)
            
        case .failed(let error):
            print("Diagnosis failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    private func handleDiagnosisResults(_ diagnosis: PreCallDiagnosis) {
        print("MOS Score: \(diagnosis.mos)")
        print("Quality: \(diagnosis.quality.rawValue)")
        print("Average Jitter: \(diagnosis.jitter.avg) seconds")
        print("Average RTT: \(diagnosis.rtt.avg) seconds")
        
        // Make decisions based on results
        if diagnosis.mos >= 4.0 {
            showMessage("Excellent call quality expected! 🟢")
        } else if diagnosis.mos >= 3.0 {
            showMessage("Good call quality expected 🟡")
        } else {
            showMessage("Poor call quality - check your network 🔴")
        }
    }
    
    // Implement other required TxClientDelegate methods...
}
```

### Advanced Usage

```swift
// Get detailed metrics
let diagnosis = // ... from completed state

// Access detailed jitter information
print("Jitter - Min: \(diagnosis.jitter.min)s, Max: \(diagnosis.jitter.max)s, Avg: \(diagnosis.jitter.avg)s")

// Access detailed RTT information
print("RTT - Min: \(diagnosis.rtt.min)s, Max: \(diagnosis.rtt.max)s, Avg: \(diagnosis.rtt.avg)s")

// Check packet statistics
print("Packets sent: \(diagnosis.packetsSent), received: \(diagnosis.packetsReceived)")
print("Bytes sent: \(diagnosis.bytesSent), received: \(diagnosis.bytesReceived)")

// Calculate packet loss rate
let packetLoss = Double(diagnosis.packetsSent - diagnosis.packetsReceived) / Double(diagnosis.packetsSent)
print("Packet loss: \(String(format: "%.1f", packetLoss * 100))%")

// Convert to dictionary for analytics
let diagnosisDict = diagnosis.toDictionary()
sendToAnalytics(diagnosisDict)
```

## Data Models

### PreCallDiagnosis

The main result object containing all diagnosis metrics:

```swift
public struct PreCallDiagnosis {
    public let mos: Double                    // Mean Opinion Score (1.0-5.0)
    public let quality: CallQuality          // Quality category
    public let jitter: MetricSummary         // Jitter statistics
    public let rtt: MetricSummary           // RTT statistics
    public let bytesSent: Int64             // Total bytes sent
    public let bytesReceived: Int64         // Total bytes received
    public let packetsSent: Int64           // Total packets sent
    public let packetsReceived: Int64       // Total packets received
    public let iceCandidates: [ICECandidate] // ICE candidates
}
```

### MetricSummary

Statistical summary for metrics like jitter and RTT:

```swift
public struct MetricSummary {
    public let min: Double    // Minimum value
    public let max: Double    // Maximum value
    public let avg: Double    // Average value
}
```

### PreCallDiagnosisState

Enum representing the current state of the diagnosis:

```swift
public enum PreCallDiagnosisState {
    case started                              // Diagnosis has started
    case completed(PreCallDiagnosis)         // Diagnosis completed with results
    case failed(Error?)                     // Diagnosis failed
}
```

## Quality Interpretation

### MOS Score Guidelines

- **4.0 - 5.0**: Excellent quality - Users are very satisfied
- **3.0 - 3.9**: Good quality - Users are satisfied
- **2.0 - 2.9**: Fair quality - Some users may be dissatisfied
- **1.0 - 1.9**: Poor quality - Many users are dissatisfied

### Network Metrics Guidelines

- **Jitter**: 
  - < 20ms: Excellent
  - 20-50ms: Good
  - 50-100ms: Fair
  - > 100ms: Poor

- **RTT (Round Trip Time)**:
  - < 100ms: Excellent
  - 100-200ms: Good
  - 200-400ms: Fair
  - > 400ms: Poor

- **Packet Loss**:
  - < 1%: Excellent
  - 1-3%: Good
  - 3-5%: Fair
  - > 5%: Poor

## Error Handling

The diagnosis can fail for several reasons:

```swift
func onPreCallDiagnosisStateUpdated(state: PreCallDiagnosisState) {
    switch state {
    case .failed(let error):
        if let txError = error as? TxError {
            switch txError {
            case .callFailed(let reason):
                switch reason {
                case .destinationNumberIsRequired:
                    print("Test number is required")
                case .sessionIdIsRequired:
                    print("Client not connected")
                case .noMetricsCollected:
                    print("Test call ended too quickly")
                case .callNotFound:
                    print("Test call was not found")
                default:
                    print("Call failed: \(reason)")
                }
            case .socketConnectionFailed:
                print("Network connection issue")
            default:
                print("Other error: \(txError)")
            }
        }
    default:
        break
    }
}
```

## Best Practices

1. **Test Number**: Use a dedicated test number that can handle automated calls
2. **Duration**: 10-15 seconds is usually sufficient for accurate metrics
3. **Timing**: Run diagnosis before important calls or when network conditions change
4. **User Experience**: Show progress indicators and clear results to users
5. **Analytics**: Log diagnosis results for network quality monitoring
6. **Fallback**: Always allow users to make calls even if diagnosis fails

## Integration with Android

This iOS implementation mirrors the Android PreCallDiagnosis feature, ensuring consistent behavior across platforms:

- Same data structure and metrics
- Similar API design
- Consistent quality thresholds
- Compatible result formats

## Example Project

See `Examples/PreCallDiagnosisExample.swift` for a complete implementation example.

## Requirements

- iOS 12.0+
- TelnyxRTC SDK
- Active Telnyx account with calling capabilities
- Test phone number for diagnosis calls