import Foundation
import SwiftUI

struct GuardianSettingsView: View {
    let currentUserId: Int // Accept ID directly from parent view
    @StateObject private var service = GuardianService()

    @State private var showingAddGuardianAlert = false
    @State private var newGuardianName = ""
    @State private var newGuardianPhone = ""
    
    // Passcode state properties
    @State private var passcode: String = ""
    @State private var isSavingPasscode = false
    @State private var passcodeMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Call Screening Passcode Section
                Section(header: Text("Call Screening Passcode"), footer: Text("Callers must provide this exact passcode to pass your voice screening.")) {
                    HStack {
                        SecureField("Passcode", text: $passcode)
                            .keyboardType(.numberPad)
                        
                        Button(action: {
                            updatePasscode()
                        }) {
                            if isSavingPasscode {
                                ProgressView()
                            } else {
                                Text("Update")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(passcode.isEmpty || isSavingPasscode)
                    }
                    
                    if !passcodeMessage.isEmpty {
                        Text(passcodeMessage)
                            .font(.caption)
                            .foregroundColor(passcodeMessage.contains("success") ? .green : .red)
                    }
                }

                // MARK: - Registered Guardians Section
                Section(header: Text("Registered Guardians")) {
                    if service.isLoading {
                        ProgressView()
                    } else if service.guardians.isEmpty {
                        Text("No guardians assigned yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(service.guardians) { guardian in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(guardian.guardian_name)
                                        .font(.headline)
                                    Text(guardian.guardian_phone)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let guardian = service.guardians[index]
                                if let id = guardian.id {
                                    service.deleteGuardian(id: id, userId: currentUserId) { success in
                                        if success {
                                            print("✅ Guardian deleted successfully")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: {
                        showingAddGuardianAlert = true
                    }) {
                        Label("Add Guardian Manually", systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationTitle("Shield Settings")
            .onAppear {
                service.fetchGuardians(userId: currentUserId)
                fetchCurrentPasscode()
            }
            .alert("Add Guardian", isPresented: $showingAddGuardianAlert) {
                TextField("Guardian Name", text: $newGuardianName)
                TextField("Phone Number", text: $newGuardianPhone)
                    .keyboardType(.phonePad)
                Button("Save") {
                    if !newGuardianName.isEmpty && !newGuardianPhone.isEmpty {
                        service.addGuardian(userId: currentUserId, name: newGuardianName, phone: newGuardianPhone) { success in
                            if success {
                                newGuardianName = ""
                                newGuardianPhone = ""
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the name and phone number of the guardian.")
            }
        }
    }
    
    // MARK: - Passcode Network Methods
    private func fetchCurrentPasscode() {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/\(currentUserId)/passcode") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fetchedPasscode = json["passcode"] as? String {
                DispatchQueue.main.async {
                    self.passcode = fetchedPasscode
                }
            }
        }.resume()
    }
    
    private func updatePasscode() {
        isSavingPasscode = true
        passcodeMessage = ""
        
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/user/\(currentUserId)/passcode") else {
            isSavingPasscode = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["passcode": passcode]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isSavingPasscode = false
                if let error = error {
                    passcodeMessage = "Error: \(error.localizedDescription)"
                    return
                }
                passcodeMessage = "Passcode updated successfully!"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    passcodeMessage = ""
                }
            }
        }.resume()
    }
}
