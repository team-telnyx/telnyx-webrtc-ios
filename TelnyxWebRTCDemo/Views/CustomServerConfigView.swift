//
//  CustomServerConfigView.swift
//  TelnyxWebRTCDemo
//
//  Created by Claude Code
//

import SwiftUI

struct CustomServerConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isEnabled: Bool = false
    @State private var host: String = ""
    @State private var port: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    let userDefaults = UserDefaults.standard
    let onSave: () -> Void

    init(onSave: @escaping () -> Void) {
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Server Configuration")
                    .font(.headline)) {
                    Toggle(isOn: $isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Custom Server")
                                .font(.body)
                            Text("Use a custom signaling server")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                }

                if isEnabled {
                    Section(header: Text("Server Details")
                        .font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Host / IP Address")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("e.g., 192.168.1.100 or rtc.example.com", text: $host)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Port")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("e.g., 8080", text: $port)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("The server URL will be:")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } icon: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }

                            if !host.isEmpty && !port.isEmpty {
                                Text("wss://\(host):\(port)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            } else {
                                Text("wss://[host]:[port]")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                Text("Important")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }

                            Text("• You must disconnect and reconnect for changes to take effect")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("• The custom server must support WebSocket Secure (wss://)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("• Invalid configuration may prevent connections")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationBarTitle("Custom Server", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveConfiguration()
                }
                .disabled(isEnabled && (host.isEmpty || port.isEmpty))
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Configuration Saved"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                        onSave()
                    }
                )
            }
        }
        .onAppear {
            loadConfiguration()
        }
    }

    private func loadConfiguration() {
        isEnabled = userDefaults.getCustomServerEnabled()
        host = userDefaults.getCustomServerHost()
        port = userDefaults.getCustomServerPort()
    }

    private func saveConfiguration() {
        userDefaults.saveCustomServerEnabled(isEnabled)
        userDefaults.saveCustomServerHost(host)
        userDefaults.saveCustomServerPort(port)
        userDefaults.synchronize()

        if isEnabled {
            alertMessage = "Custom server configuration saved:\nwss://\(host):\(port)\n\nPlease disconnect and reconnect to apply changes."
        } else {
            alertMessage = "Custom server disabled. The default Telnyx server will be used.\n\nPlease disconnect and reconnect to apply changes."
        }

        showAlert = true
    }
}

struct CustomServerConfigView_Previews: PreviewProvider {
    static var previews: some View {
        CustomServerConfigView(onSave: {})
    }
}
