//
//  AnonymousLoginSheet.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 23/09/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import SwiftUI

struct AnonymousLoginSheet: View {
    @Binding var assistantId: String
    @Binding var targetType: String
    @Binding var targetVersionId: String
    
    let onConnect: (String, String, String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("AI Assistant Anonymous Login")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("Connect to an AI Assistant using anonymous login. This allows you to interact with AI assistants without traditional authentication.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assistant ID")
                            .font(.headline)
                        TextField("Enter Assistant ID", text: $assistantId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityIdentifier("assistantIdTextField")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Type")
                            .font(.headline)
                        TextField("Target Type", text: $targetType)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityIdentifier("targetTypeTextField")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Version ID (Optional)")
                            .font(.headline)
                        TextField("Enter Version ID", text: $targetVersionId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityIdentifier("targetVersionIdTextField")
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button(action: {
                        onConnect(assistantId, targetType, targetVersionId)
                    }) {
                        Text("Connect to AI Assistant")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#00E3AA"))
                            .cornerRadius(12)
                    }
                    .disabled(assistantId.isEmpty || targetType.isEmpty)
                    .accessibilityIdentifier("connectButton")
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#1D1D1D"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#1D1D1D"), lineWidth: 1)
                            )
                    }
                    .accessibilityIdentifier("cancelButton")
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AnonymousLoginSheet(
        assistantId: .constant("assistant-9be2960c-df97-4cbb-9f1a-28c87d0ab77e"),
        targetType: .constant("ai_assistant"),
        targetVersionId: .constant(""),
        onConnect: { _, _, _ in },
        onCancel: { }
    )
}