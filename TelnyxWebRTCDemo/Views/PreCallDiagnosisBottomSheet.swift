//
//  PreCallDiagnosisBottomSheet.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 12/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import SwiftUI
import TelnyxRTC

struct PreCallDiagnosisBottomSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var preCallDiagnosisState: PreCallDiagnosisState?
    @State private var isRunningDiagnosis = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Text("Pre-call Diagnosis Report")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#1D1D1D"))
                        
                        Spacer()
                        
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(Color(hex: "#525252"))
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Status and Action Section
                    VStack(spacing: 16) {
                        if isRunningDiagnosis {
                            VStack(spacing: 12) {
                                Text("Running Pre-call Diagnosis...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "#1D1D1D"))
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#00E3AA")))
                                    .scaleEffect(1.2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            Button(action: startPreCallDiagnosis) {
                                Text("Start Pre-call Diagnosis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(hex: "#00E3AA"))
                                    .cornerRadius(8)
                            }
                            .disabled(viewModel.socketState != .connected && viewModel.socketState != .clientReady)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Results Section
                    if case .completed(let diagnosis) = preCallDiagnosisState {
                        DiagnosisResultsView(diagnosis: diagnosis)
                            .padding(.horizontal, 20)
                    } else if case .failed(let error) = preCallDiagnosisState {
                        VStack(spacing: 8) {
                            Text("Pre-call Diagnosis Failed")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#D40000"))
                            
                            if let error = error {
                                Text(error.localizedDescription)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#525252"))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FFF5F5"))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onReceive(viewModel.preCallDiagnosisStatePublisher) { state in
            self.preCallDiagnosisState = state
            if case .started = state {
                isRunningDiagnosis = true
            } else {
                isRunningDiagnosis = false
            }
        }
    }
    
    private func startPreCallDiagnosis() {
        guard viewModel.socketState == .connected || viewModel.socketState == .clientReady else {
            return
        }
        
        isRunningDiagnosis = true
        preCallDiagnosisState = .started
        
        // Start the diagnosis with default parameters
        viewModel.startPreCallDiagnosis(
            destinationNumber: "echo",
            duration: 10.0
        )
    }
}

struct DiagnosisResultsView: View {
    let diagnosis: PreCallDiagnosis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Network Quality Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Network Quality")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                
                MetricRow(label: "Quality", value: diagnosis.quality.rawValue.capitalized)
                MetricRow(label: "MOS Score", value: String(format: "%.2f", diagnosis.mos))
            }
            
            // Jitter Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Jitter")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                
                MetricRow(label: "Min", value: String(format: "%.2f ms", diagnosis.jitter.min * 1000))
                MetricRow(label: "Max", value: String(format: "%.2f ms", diagnosis.jitter.max * 1000))
                MetricRow(label: "Average", value: String(format: "%.2f ms", diagnosis.jitter.avg * 1000))
            }
            
            // RTT Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Round Trip Time (RTT)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                
                MetricRow(label: "Min", value: String(format: "%.2f ms", diagnosis.rtt.min * 1000))
                MetricRow(label: "Max", value: String(format: "%.2f ms", diagnosis.rtt.max * 1000))
                MetricRow(label: "Average", value: String(format: "%.2f ms", diagnosis.rtt.avg * 1000))
            }
            
            // Session Stats Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Statistics")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                
                MetricRow(label: "Bytes Sent", value: "\(diagnosis.bytesSent)")
                MetricRow(label: "Bytes Received", value: "\(diagnosis.bytesReceived)")
                MetricRow(label: "Packets Sent", value: "\(diagnosis.packetsSent)")
                MetricRow(label: "Packets Received", value: "\(diagnosis.packetsReceived)")
            }
            
            // ICE Candidates Section
            if !diagnosis.iceCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ICE Candidates")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#1D1D1D"))
                    
                    ForEach(diagnosis.iceCandidates.indices, id: \.self) { index in
                        let candidate = diagnosis.iceCandidates[index]
                        ICECandidateRow(candidate: candidate)
                    }
                }
            }
        }
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#525252"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#1D1D1D"))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color(hex: "#F8F9FA"))
        .cornerRadius(6)
    }
}

struct ICECandidateRow: View {
    let candidate: ICECandidate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Candidate \(candidate.id)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#1D1D1D"))
            
            Text("\(candidate.type), \(candidate.protocol), \(candidate.address):\(candidate.port), Priority: \(candidate.priority)")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#525252"))
                .lineLimit(3)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(hex: "#F0F0F0"))
        .cornerRadius(6)
    }
}

struct PreCallDiagnosisBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        PreCallDiagnosisBottomSheet(
            isPresented: .constant(true),
            viewModel: HomeViewModel()
        )
    }
}