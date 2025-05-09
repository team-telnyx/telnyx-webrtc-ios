import SwiftUI
import TelnyxRTC

struct CallQualityMetricsView: View {
    let metrics: CallQualityMetrics
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Call Quality Metrics")
                .font(.system(size: 16).bold())
                .foregroundColor(Color(hex: "#1D1D1D"))
            
            // Main metrics
            VStack(spacing: 12) {
                metricRow(title: "Jitter:", value: "\(metrics.jitter, specifier: "%.3f") s")
                metricRow(title: "MOS:", value: "\(metrics.mos, specifier: "%.1f")")
                metricRow(title: "Quality:", value: metrics.quality.rawValue.capitalized)
            }
            
            // Inbound Audio Stats
            if let inboundAudio = metrics.inboundAudio, !inboundAudio.isEmpty {
                audioStatsSection(title: "Inbound Audio", stats: inboundAudio)
            }
            
            // Outbound Audio Stats
            if let outboundAudio = metrics.outboundAudio, !outboundAudio.isEmpty {
                audioStatsSection(title: "Outbound Audio", stats: outboundAudio)
            }
            
            // Close button
            Button(action: onClose) {
                Text("Close")
                    .font(.system(size: 16).bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#1D1D1D"))
                    .cornerRadius(20)
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.dtmfClose)
            .padding(.horizontal, 60)
            .padding(.top, 20)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding()
    }
    
    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
            Spacer()
            Text(value)
                .font(.system(size: 14).bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#F5F3E4"))
        .cornerRadius(5)
    }
    
    private func audioStatsSection(title: String, stats: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14).bold())
                .foregroundColor(Color(hex: "#1D1D1D"))
                .padding(.top, 4)
            
            // Display key stats
            Group {
                if let packetsReceived = stats["packetsReceived"] as? Int {
                    audioStatRow(title: "Packets Received:", value: "\(packetsReceived)")
                }
                
                if let packetsLost = stats["packetsLost"] as? Int {
                    audioStatRow(title: "Packets Lost:", value: "\(packetsLost)")
                }
                
                if let jitter = stats["jitter"] as? Double {
                    audioStatRow(title: "Jitter:", value: "\(jitter, specifier: "%.3f") s")
                }
                
                if let bytesReceived = stats["bytesReceived"] as? Int {
                    audioStatRow(title: "Bytes Received:", value: "\(bytesReceived)")
                }
                
                if let bytesSent = stats["bytesSent"] as? Int {
                    audioStatRow(title: "Bytes Sent:", value: "\(bytesSent)")
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func audioStatRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
            Spacer()
            Text(value)
                .font(.system(size: 12).bold())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "#F5F3E4").opacity(0.7))
        .cornerRadius(3)
    }
}

struct CallQualityMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        let inboundAudioStats: [String: Any] = [
            "audioLevel": 3.051850947599719e-05,
            "transportId": "T01",
            "trackIdentifier": "d5b70c94-0db7-42ee-bfcf-704604f306f0",
            "totalAudioEnergy": 3.073552088100552e-10,
            "packetsDiscarded": 0,
            "mid": 0,
            "jitterBufferDelay": 643.2,
            "type": "inbound-rtp",
            "id": "IT01A3376722818",
            "packetsLost": 0,
            "delayedPacketOutageSamples": 3360,
            "codecId": "CIT01_102_minptime=10;useinbandfec=1",
            "timestamp": 1746801919015.509,
            "jitterBufferTargetDelay": 1228.8,
            "removedSamplesForAcceleration": 0,
            "interruptionCount": 0,
            "relativePacketArrivalDelay": 0.22,
            "jitter": 0.01,
            "fecPacketsReceived": 0,
            "fecPacketsDiscarded": 0,
            "packetsReceived": 21,
            "jitterBufferEmittedCount": 15360,
            "totalSamplesReceived": 57600,
            "headerBytesReceived": 252,
            "lastPacketReceivedTimestamp": 1746801919005.599,
            "jitterBufferMinimumDelay": 1075.2,
            "insertedSamplesForDeceleration": 480,
            "totalSamplesDuration": 1.200000000000001,
            "silentConcealedSamples": 38760,
            "concealmentEvents": 2,
            "kind": "audio",
            "concealedSamples": 41760,
            "ssrc": 3376722818,
            "totalInterruptionDuration": 0,
            "jitterBufferFlushes": 1,
            "bytesReceived": 168
        ]

        let outboundAudioStats: [String: Any] = [
            "ssrc": 3785125107,
            "active": 1,
            "id": "OT01A3785125107",
            "headerBytesSent": 264,
            "codecId": "COT01_102_maxaveragebitrate=30000;maxplaybackrate=48000;minptime=10;stereo=0;useinbandfec=1",
            "mid": 0,
            "targetBitrate": 30000,
            "nackCount": 0,
            "retransmittedPacketsSent": 0,
            "packetsSent": 22,
            "kind": "audio",
            "timestamp": 1746801919015.509,
            "totalPacketSendDelay": 0,
            "bytesSent": 1386,
            "type": "outbound-rtp",
            "retransmittedBytesSent": 0,
            "transportId": "T01",
            "mediaSourceId": "SA1"
        ]

        let callQualityMetrics = CallQualityMetrics(
            jitter: 0.01,
            rtt: 0.0,
            mos: 4.404592027648,
            quality: .excellent,
            inboundAudio: inboundAudioStats,
            outboundAudio: outboundAudioStats,
            remoteInboundAudio: nil,
            remoteOutboundAudio: nil
        )
        
        return CallQualityMetricsView(metrics: callQualityMetrics, onClose: {})
            .previewLayout(.sizeThatFits)
    }
}