//
//  WebSocketMessagesBottomSheet.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 2024-11-24.
//  Copyright © 2024 Telnyx LLC. All rights reserved.
//

import SwiftUI
import TelnyxRTC

struct WebSocketMessagesBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var messageManager = WebSocketMessageManager.shared
    @State private var showingShareSheet = false
    @State private var shareText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView

                if messageManager.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesList
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: [shareText])
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.blue)

            Spacer()

            Text("Websocket Messages")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Button("Clear") {
                messageManager.clearMessages()
            }
            .foregroundColor(.red)
            .disabled(messageManager.messages.isEmpty)
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

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("No Websocket Messages")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)

            Text("Websocket messages will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var messagesList: some View {
        VStack {
            HStack {
                Spacer()

                Button("Share") {
                    shareText = messageManager.exportMessages()
                    showingShareSheet = true
                }
                .disabled(messageManager.messages.isEmpty)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollViewReader { proxy in
                List {
                    ForEach(messageManager.messages) { message in
                        WebSocketMessageRow(message: message)
                    }
                }
                .listStyle(PlainListStyle())
                .onChange(of: messageManager.messages.count) { _ in
                    if let lastMessage = messageManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    if let lastMessage = messageManager.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct WebSocketMessageRow: View {
    let message: WebSocketMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Text(message.formattedContent)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct WebSocketMessagesBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        WebSocketMessagesBottomSheet()
    }
}
