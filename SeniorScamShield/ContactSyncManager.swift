import Foundation
import Contacts
import SwiftUI
import Combine

class ContactSyncManager: ObservableObject {
    @Published var localDeviceContacts: [MCSContactModel] = []
    @Published var backendMCSContacts: [MCSContactModel] = []
    @Published var unsyncedContacts: [MCSContactModel] = []
    @Published var syncedContacts: [MCSContactModel] = []

    func fetchDeviceContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        var results: [MCSContactModel] = []

        try? store.enumerateContacts(with: request) { contact, _ in
            let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            for phoneVal in contact.phoneNumbers {
                let phoneString = phoneVal.value.stringValue
                results.append(MCSContactModel(id: nil, name: fullName.isEmpty ? "Unknown" : fullName, phoneNumber: phoneString, isTrusted: false))
            }
        }

        DispatchQueue.main.async {
            self.localDeviceContacts = results
            self.compareLists()
        }
    }

    func fetchBackendContacts(userId: Int) {
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/contacts?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            if let decoded = try? JSONDecoder().decode([MCSContactModel].self, from: data) {
                DispatchQueue.main.async {
                    self.backendMCSContacts = decoded
                    self.compareLists()
                }
            }
        }.resume()
    }

    private func compareLists() {
        let backendNormalizedNumbers = Set(backendMCSContacts.map { $0.phoneNumber.normalizedPhoneNumber })
        unsyncedContacts = localDeviceContacts.filter { !backendNormalizedNumbers.contains($0.phoneNumber.normalizedPhoneNumber) }
        syncedContacts = localDeviceContacts.filter { backendNormalizedNumbers.contains($0.phoneNumber.normalizedPhoneNumber) }
    }
}
