//
//  CallHistoryBottomSheet.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 02/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import SwiftUI
import TelnyxRTC

/// SwiftUI bottom sheet component for displaying call history
public struct CallHistoryBottomSheet: View {
    
    @StateObject private var database = CallHistoryDatabase.shared
    @Environment(\.dismiss) private var dismiss
    
    /// Current profile ID to filter call history
    public let profileId: String
    
    /// Callback for when user wants to redial a number
    public let onRedial: (String, String?) -> Void
    
    /// Callback for when user wants to clear history
    public let onClearHistory: () -> Void
    
    @State private var showingClearAlert = false
    @State private var filteredHistory: [CallHistoryEntry] = []
    
    public init(
        profileId: String,
        onRedial: @escaping (String, String?) -> Void,
        onClearHistory: @escaping () -> Void
    ) {
        self.profileId = profileId
        self.onRedial = onRedial
        self.onClearHistory = onClearHistory
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Call History List
                if filteredHistory.isEmpty {
                    emptyStateView
                } else {
                    callHistoryList
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                updateFilteredHistory()
            }
            .onReceive(database.$callHistory) { _ in
                updateFilteredHistory()
            }
        }
        .alert("Clear Call History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                database.clearCallHistory(for: profileId)
                onClearHistory()
            }
        } message: {
            Text("This will permanently delete all call history for this profile.")
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.blue)
            
            Spacer()
            
            Text("Call History")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("Clear") {
                showingClearAlert = true
            }
            .foregroundColor(.red)
            .disabled(filteredHistory.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Call History")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Your recent calls will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Call History List
    
    private var callHistoryList: some View {
        List {
            ForEach(filteredHistory, id: \.callId) { entry in
                CallHistoryRow(
                    entry: entry,
                    onRedial: { phoneNumber, callerName in
                        onRedial(phoneNumber, callerName)
                        dismiss()
                    }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .onDelete(perform: deleteEntries)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func updateFilteredHistory() {
        filteredHistory = database.getCallHistory(for: profileId)
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredHistory[index]
            database.deleteCallHistoryEntry(callId: entry.callId)
        }
    }
}

// MARK: - Call History Row

struct CallHistoryRow: View {
    let entry: CallHistoryEntry
    let onRedial: (String, String?) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Call Direction Icon
            callDirectionIcon
            
            // Call Information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.callerName ?? entry.phoneNumber)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(entry.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if entry.callerName != nil {
                        Text(entry.phoneNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if entry.duration > 0 {
                        Text(entry.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Call Status
                Text(entry.callStatus.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            // Redial Button
            Button(action: {
                onRedial(entry.phoneNumber, entry.callerName)
            }) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.green)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
    }
    
    private var callDirectionIcon: some View {
        Image(systemName: entry.isIncoming ? "phone.down.fill" : "phone.up.fill")
            .font(.system(size: 16))
            .foregroundColor(entry.isIncoming ? .blue : .green)
            .frame(width: 24, height: 24)
    }
    
    private var statusColor: Color {
        switch entry.callStatus {
        case "answered":
            return .green
        case "missed":
            return .red
        case "rejected":
            return .orange
        case "failed":
            return .red
        case "cancelled":
            return .gray
        default:
            return .secondary
        }
    }
}

// MARK: - Preview

struct CallHistoryBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        CallHistoryBottomSheet(
            profileId: "test-profile",
            onRedial: { phoneNumber, callerName in
                print("Redial: \(phoneNumber)")
            },
            onClearHistory: {
                print("Clear history")
            }
        )
    }
}