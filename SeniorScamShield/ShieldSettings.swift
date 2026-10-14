import SwiftUI

struct ShieldSettings: View {
    @AppStorage("loggedInUserId") private var loggedInUserId: Int = 0
    @AppStorage("isGuardianShieldActive") private var isGuardianShieldActive: Bool = true
    
    @State private var ownerPin: String = ""
    @State private var newPasscode: String = ""
    @State private var isUpdating: Bool = false
    @State private var statusMessage: String = ""
    @State private var isError: Bool = false

    var body: some View {
        Form {
            // MARK: - Protection Status Section
            Section(header: Text("Protection Status")) {
                Toggle(isOn: $isGuardianShieldActive) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Guardian Shield Active")
                            .font(.headline)
                        Text(isGuardianShieldActive ? "Call screening is actively protecting your device." : "Call screening is currently disabled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.green)
            }

            // MARK: - Passcode Configuration Section
            Section(
                header: Text("Call Screening Security"),
                footer: Text("Enter your Owner PIN to securely update your call screening passcode.")
            ) {
                SecureField("Owner PIN", text: $ownerPin)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                
                SecureField("New Passcode", text: $newPasscode)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                
                Button(action: {
                    updatePasscode()
                }) {
                    HStack {
                        Spacer()
                        if isUpdating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Update Passcode")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
                .background(ownerPin.isEmpty || newPasscode.isEmpty || isUpdating ? Color.gray : Color.blue)
                .cornerRadius(10)
                .disabled(ownerPin.isEmpty || newPasscode.isEmpty || isUpdating)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(isError ? .red : .green)
                }
            }
        }
        .navigationTitle("Shield Settings")
    }

    private func updatePasscode() {
        isUpdating = true
        statusMessage = ""
        isError = false

        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/settings/update-passcode") else {
            isUpdating = false
            statusMessage = "Invalid server URL."
            isError = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "userId": loggedInUserId,
            "pin": ownerPin.trimmingCharacters(in: .whitespaces),
            "newPasscode": newPasscode.trimmingCharacters(in: .whitespaces)
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUpdating = false

                if let error = error {
                    statusMessage = "Network error: \(error.localizedDescription)"
                    isError = true
                    return
                }

                guard let data = data else {
                    statusMessage = "No response from server."
                    isError = true
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let success = json["success"] as? Bool ?? false
                        if success {
                            statusMessage = "Passcode updated successfully!"
                            isError = false
                            ownerPin = ""
                            newPasscode = ""
                        } else {
                            statusMessage = json["error"] as? String ?? "Failed to update passcode."
                            isError = true
                        }
                    }
                } catch {
                    statusMessage = "Failed to parse server response."
                    isError = true
                }
            }
        }.resume()
    }
}
