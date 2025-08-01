//
//  TranscriptDialogView.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 31/07/2025.
//

import SwiftUI
import TelnyxRTC

struct TranscriptDialogView: View {
    @ObservedObject var viewModel: AIAssistantViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var messageInput: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        Text("Assistant Conversation")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                .background(Color(hex: "#00E3AA"))
                
                // Transcript List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if viewModel.transcriptions.isEmpty {
                                VStack(spacing: 15) {
                                    Image(systemName: "text.bubble.rtl")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color.gray.opacity(0.5))
                                    
                                    Text("No conversation yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color.gray)
                                    
                                    Text("Start talking with the assistant to see the conversation here.")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                ForEach(viewModel.transcriptions, id: \.id) { item in
                                    TranscriptItemView(item: item)
                                        .id(item.id)
                                }
                                
                                // Invisible view for scrolling to bottom
                                HStack { }
                                    .id("bottom")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .onAppear {
                        if !viewModel.transcriptions.isEmpty {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom")
                            }
                        }
                    }
                    .onChange(of: viewModel.transcriptions.count) { _ in
                        if !viewModel.transcriptions.isEmpty {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom")
                            }
                        }
                    }
                }
                
                // Message Input
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                              Color.gray : Color(hex: "#00E3AA"))
                                )
                        }
                        .disabled(messageInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(UIColor.systemBackground))
            }
            .navigationBarHidden(true)
        }
    }
    
    private func sendMessage() {
        let message = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        viewModel.sendMessage(message)
        messageInput = ""
    }
}

struct TranscriptItemView: View {
    let item: TranscriptionItem
    
    private var isUser: Bool {
        return item.speaker.lowercased().contains("user") || 
               item.speaker.lowercased().contains("human") ||
               item.speaker.lowercased() == "you"
    }
    
    private var displayName: String {
        if isUser {
            return "You"
        } else {
            return item.speaker.capitalized
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer()
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                HStack {
                    if !isUser {
                        Text(displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#525252"))
                    }
                    
                    Spacer()
                    
                    Text(formatTime(item.timestamp))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.7))
                    
                    if isUser {
                        Text(displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#525252"))
                    }
                }
                
                Text(item.text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "#1D1D1D"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isUser ? Color(hex: "#00E3AA").opacity(0.1) : Color.gray.opacity(0.1))
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
                
                if let confidence = item.confidence {
                    Text("Confidence: \(Int(confidence * 100))%")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            
            if !isUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TranscriptDialogView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptDialogView(viewModel: AIAssistantViewModel())
    }
}
