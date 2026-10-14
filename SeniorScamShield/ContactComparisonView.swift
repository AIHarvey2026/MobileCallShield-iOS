import SwiftUI

struct ContactComparisonView: View {
    @StateObject private var syncManager = ContactSyncManager()
    @AppStorage("loggedInUserId") private var userId: Int = 0
    @State private var searchText = ""
    
    // Filtered computed properties for search
    var filteredSyncedContacts: [MCSContactModel] {
        if searchText.isEmpty {
            return syncManager.syncedContacts
        } else {
            return syncManager.syncedContacts.filter { $0.name.localizedStandardContains(searchText) || $0.phoneNumber.contains(searchText) }
        }
    }
    
    var filteredUnsyncedContacts: [MCSContactModel] {
        if searchText.isEmpty {
            return syncManager.unsyncedContacts
        } else {
            return syncManager.unsyncedContacts.filter { $0.name.localizedStandardContains(searchText) || $0.phoneNumber.contains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Protected Contacts (\(filteredSyncedContacts.count))")) {
                    if filteredSyncedContacts.isEmpty {
                        Text("No matching protected contacts found.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredSyncedContacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.headline)
                                    Text(contact.phoneNumber)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section(header: Text("Unsynced Contacts (\(filteredUnsyncedContacts.count))")) {
                    if filteredUnsyncedContacts.isEmpty {
                        Text("No matching unsynced contacts found.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredUnsyncedContacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name)
                                        .font(.headline)
                                    Text(contact.phoneNumber)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Button(action: {
                                    addContactToBackend(contact)
                                }) {
                                    Text("Shield")
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Contact Shield Status")
            .searchable(text: $searchText, prompt: "Search by name or number")
            .onAppear {
                syncManager.fetchDeviceContacts()
                if userId > 0 {
                    syncManager.fetchBackendContacts(userId: userId)
                }
            }
        }
    }
    
    private func addContactToBackend(_ contact: MCSContactModel) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/contacts") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "name": contact.name,
            "phoneNumber": contact.phoneNumber,
            "isTrusted": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    syncManager.fetchBackendContacts(userId: userId)
                    syncManager.fetchDeviceContacts()
                }
            }
        }.resume()
    }
}
