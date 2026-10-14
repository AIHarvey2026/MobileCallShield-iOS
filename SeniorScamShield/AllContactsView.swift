import SwiftUI

// MARK: - Remote Trusted Contact Model
struct RemoteTrustedContact: Identifiable, Codable {
    let id: Int
    let name: String
    let phoneNumber: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phoneNumber = "phone_number"
    }
}

// MARK: - All Contacts View
struct AllContactsView: View {
    @State private var contacts: [RemoteTrustedContact] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingContactPicker = false
    let currentUserId: Int = 1 // Matches your logged-in user context

    var body: some View {
        List {
            // MARK: - Actions Section to Trigger Picker
            Section(header: Text("Actions")) {
                Button(action: {
                    showingContactPicker = true
                }) {
                    Label("Select from Phone Contacts", systemImage: "person.crop.badge.plus")
                }
            }

            // MARK: - Trusted Contacts List Section
            Section(header: Text("Trusted Contacts")) {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading trusted contacts...")
                        Spacer()
                    }
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if contacts.isEmpty {
                    Text("No trusted contacts found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(contacts) { contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Trusted Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchContacts()
        }
        // MARK: - Multi-Select Contact Picker Sheet Presentation
        .sheet(isPresented: $showingContactPicker) {
            ContactPicker { selectedList in
                // Handle multiple selected contacts from the native iOS picker
                for newContact in selectedList {
                    uploadTrustedContact(name: newContact.name, phoneNumber: newContact.phoneNumber)
                }
                showingContactPicker = false
            }
        }
    }

    private func fetchContacts() {
        isLoading = true
        errorMessage = ""
         
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts/\(currentUserId)") else {
            isLoading = false
            errorMessage = "Invalid backend URL."
            return
        }
         
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                 
                guard let data = data else {
                    errorMessage = "No data returned."
                    return
                }
                 
                do {
                    contacts = try JSONDecoder().decode([RemoteTrustedContact].self, from: data)
                } catch {
                    errorMessage = "Failed to parse contact list."
                }
            }
        }.resume()
    }

    private func uploadTrustedContact(name: String, phoneNumber: String) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/trusted-contacts") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "user_id": currentUserId,
            "name": name,
            "phone_number": phoneNumber
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // Refresh list after successful addition
                    fetchContacts()
                }
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        AllContactsView()
    }
}
