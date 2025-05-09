//
//  DestinationToggle.swift
//  TelnyxRTC
//
//  Created by Isaac Akakpo on 4/1/25.
//


import SwiftUI

struct DestinationToggle: View {
    @Binding var isFirstOptionSelected: Bool
    let firstOption: String
    let secondOption: String
    
    init(isFirstOptionSelected: Binding<Bool>, firstOption: String, secondOption: String) {
        self._isFirstOptionSelected = isFirstOptionSelected
        self.firstOption = firstOption
        self.secondOption = secondOption
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // First option button
            Button(action: {
                withAnimation {
                    isFirstOptionSelected = false
                }
            }) {
                Text(firstOption)
                    .font(.body)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(!isFirstOptionSelected ? .white : .primary)
                    .background(!isFirstOptionSelected ? Color(hex: "#008563") : Color(.white))
            }
            
            // Second option button
            Button(action: {
                withAnimation {
                    isFirstOptionSelected = true
                }
            }) {
                Text(secondOption)
                    .font(.body)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundColor(isFirstOptionSelected ? .white : .primary)
                    .background(isFirstOptionSelected ? Color(hex: "#008563") : Color(.white))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray3), lineWidth: 1)
        )
    }
}
