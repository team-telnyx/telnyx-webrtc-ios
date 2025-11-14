//
//  TranscriptDialogView.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 31/07/2025.
//

import SwiftUI
import TelnyxRTC

class TextFieldState: ObservableObject {
    @Published var text: String = ""
}

struct TranscriptDialogView: View {
    let viewModel: AIAssistantViewModel
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var textFieldState = TextFieldState()
    @State private var localTranscriptions: [TranscriptionItem] = []
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
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
                            viewModel.closeTranscriptDialog()
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
                            if localTranscriptions.isEmpty {
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
                                ForEach(localTranscriptions, id: \.id) { item in
                                    TranscriptItemView(item: item)
                                        .equatable()
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
                        if !localTranscriptions.isEmpty {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom")
                            }
                        }
                    }
                    .onChange(of: localTranscriptions.count) { newCount in
                        // Only scroll if there are actually new items and we're not at the bottom already
                        if newCount > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo("bottom")
                                }
                            }
                        }
                    }
                }
                
                // Message Input
                VStack(spacing: 0) {
                    Divider()
                    
                    // Selected Image Preview
                    if let selectedImage = selectedImage {
                        HStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 100)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button(action: {
                                self.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    HStack(spacing: 12) {
                        // Image picker button
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: selectedImage != nil ? "photo.fill" : "photo")
                                .font(.system(size: 18))
                                .foregroundColor(selectedImage != nil ? Color(hex: "#00E3AA") : .gray)
                        }
                        
                        TextField("Type a message...", text: $textFieldState.text)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.sentences)
                            .disableAutocorrection(false)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(canSendMessage ? Color(hex: "#00E3AA") : Color.gray)
                                )
                        }
                        .disabled(!canSendMessage)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            print("TranscriptDialogView appeared")
            // Initialize local transcriptions
            localTranscriptions = viewModel.transcriptions
        }
        .onDisappear {
            print("TranscriptDialogView disappeared")
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("TranscriptionUpdated"))) { _ in
            // Update local transcriptions when notification is received
            localTranscriptions = viewModel.transcriptions
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
    }
    
    private var canSendMessage: Bool {
        return !textFieldState.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
    }
    
    private func sendMessage() {
        let message = textFieldState.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Allow sending if we have either text or image
        guard !message.isEmpty || selectedImage != nil else { return }
        
        // Use default message if only image is provided
        let finalMessage = message.isEmpty ? "What do you see in this image?" : message
        
        if let image = selectedImage {
            viewModel.sendMessageWithImage(finalMessage, image: image)
        } else {
            viewModel.sendMessage(finalMessage)
        }
        
        // Clear input
        textFieldState.text = ""
        selectedImage = nil
    }
}

struct TranscriptItemView: View, Equatable {
    let item: TranscriptionItem
    
    static func == (lhs: TranscriptItemView, rhs: TranscriptItemView) -> Bool {
        return lhs.item.id == rhs.item.id && 
               lhs.item.content == rhs.item.content &&
               lhs.item.isPartial == rhs.item.isPartial
    }
    
    // Android-compatible role detection
    private var isUser: Bool {
        return item.role.lowercased() == "user"
    }
    
    private var isAssistant: Bool {
        return item.role.lowercased() == "assistant"
    }
    
    private var displayName: String {
        if isUser {
            return "You"
        } else if isAssistant {
            return "Assistant"
        } else {
            return item.role.capitalized
        }
    }
    
    // Android-compatible styling
    private var bubbleColor: Color {
        if isUser {
            return Color(hex: "#00E3AA").opacity(0.15)
        } else if isAssistant {
            return Color(hex: "#3434EF").opacity(0.1)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    private var textColor: Color {
        return Color(hex: "#1D1D1D")
    }
    
    private var nameColor: Color {
        if isUser {
            return Color(hex: "#00E3AA")
        } else if isAssistant {
            return Color(hex: "#3434EF")
        } else {
            return Color(hex: "#525252")
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer()
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // Role and timestamp header
                HStack {
                    if !isUser {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(nameColor)
                                .frame(width: 6, height: 6)
                            
                            Text(displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(nameColor)
                        }
                    }
                    
                    Spacer()
                    
                    Text(formatTime(item.timestamp))
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.gray.opacity(0.7))
                    
                    if isUser {
                        HStack(spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(nameColor)
                            
                            Circle()
                                .fill(nameColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                // Images (if any) - displayed above message bubble
                if item.hasImages, let imageUrls = item.imageUrls {
                    HStack(spacing: 8) {
                        ForEach(imageUrls.indices, id: \.self) { index in
                            DataURLImageView(dataURL: imageUrls[index])
                                .frame(width: 150, height: 150)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)
                }

                // Message content with Android-compatible styling
                HStack {
                    if !isUser && isAssistant {
                        Image(systemName: "brain")
                            .font(.system(size: 14))
                            .foregroundColor(nameColor)
                            .padding(.leading, 8)
                    }

                    Text(item.content)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(bubbleColor)
                        )
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isUser ? .trailing : .leading)

                    if isUser {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(nameColor)
                            .padding(.trailing, 8)
                    }
                }
                
                // Status indicators (Android compatibility)
                HStack {
                    if item.isPartial {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 4, height: 4)
                            
                            Text("Recording...")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.orange)
                        }
                    }
                    
                    Spacer()
                    
                    if let confidence = item.confidence {
                        Text("Confidence: \(Int(confidence * 100))%")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }
                    
                    if let itemType = item.itemType {
                        Text(itemType)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color.gray.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
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

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Data URL Image View

struct DataURLImageView: View {
    let dataURL: String
    @State private var image: UIImage?
    @State private var isLoading: Bool = true
    @State private var hasError: Bool = false

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if isLoading {
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            } else if hasError {
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "photo.fill.on.rectangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            decodeDataURL()
        }
    }

    private func decodeDataURL() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let url = URL(string: dataURL),
                  let data = url.dataRepresentation,
                  let decodedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.hasError = true
                }
                return
            }

            DispatchQueue.main.async {
                self.image = decodedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - URL Extension for Data URL

extension URL {
    var dataRepresentation: Data? {
        // Parse data URL format: data:image/jpeg;base64,<base64-string>
        guard scheme == "data" else { return nil }

        let urlString = absoluteString

        // Split by comma to get the base64 part
        guard let commaIndex = urlString.firstIndex(of: ",") else { return nil }
        let base64String = String(urlString[urlString.index(after: commaIndex)...])

        // Decode base64
        return Data(base64Encoded: base64String, options: .ignoreUnknownCharacters)
    }
}

struct TranscriptDialogView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptDialogView(viewModel: AIAssistantViewModel())
    }
}
