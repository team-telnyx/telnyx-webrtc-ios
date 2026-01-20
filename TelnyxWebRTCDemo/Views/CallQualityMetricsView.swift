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
                metricRow(title: "Jitter:", value: "\(String(format: "%.3f", metrics.jitter)) s")
                metricRow(title: "MOS:", value: "\(String(format: "%.1f", metrics.mos))")
                metricRow(title: "Quality:", value: metrics.quality.rawValue.capitalized)
                metricRow(title: "RTT:", value: "\(String(format: "%.3f", metrics.rtt)) s")
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
            VStack(alignment: .leading, spacing: 8) {
                if let packetsReceived = stats["packetsReceived"] as? Int {
                    audioStatRow(title: "Packets Received:", value: "\(packetsReceived)")
                }
                
                if let packetsLost = stats["packetsLost"] as? Int {
                    audioStatRow(title: "Packets Lost:", value: "\(packetsLost)")
                }
                
                if let jitter = stats["jitter"] as? Double {
                    audioStatRow(title: "Jitter:", value: "\(String(format: "%.3f", jitter)) s")
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

