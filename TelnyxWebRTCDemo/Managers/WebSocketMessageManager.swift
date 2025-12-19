//
//  WebSocketMessageManager.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 2024-11-24.
//  Copyright © 2024 Telnyx LLC. All rights reserved.
//

import Foundation
import Combine

class WebSocketMessageManager: ObservableObject {
    static let shared = WebSocketMessageManager()
    
    @Published var messages: [WebSocketMessage] = []
    private let maxMessages = 1000
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupNotificationObserver()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default
            .publisher(for: .telnyxWebSocketMessageReceived)
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let message = userInfo["message"] as? String {
                    self?.addMessage(message)
                }
            }
            .store(in: &cancellables)
    }
    
    func addMessage(_ message: String) {
        let webSocketMessage = WebSocketMessage(
            id: UUID(),
            timestamp: Date(),
            content: message,
            formattedContent: formatMessage(message)
        )
        
        DispatchQueue.main.async {
            self.messages.append(webSocketMessage)
            
            if self.messages.count > self.maxMessages {
                self.messages.removeFirst(self.messages.count - self.maxMessages)
            }
        }
    }
    
    func clearMessages() {
        DispatchQueue.main.async {
            self.messages.removeAll()
        }
    }
    
    func exportMessages() -> String {
        return messages.map { $0.content }.joined(separator: "\n")
    }
    
    private func formatMessage(_ message: String) -> String {
        guard let data = message.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return message
        }
        return prettyString
    }
}

struct WebSocketMessage: Identifiable {
    let id: UUID
    let timestamp: Date
    let content: String
    let formattedContent: String
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}