import SwiftUI
import Contacts
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    var onContactsSelected: ([ImportedContact]) -> Void
    var onError: (String) -> Void = { _ in } // Default closure makes it optional
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        init(_ parent: ContactPicker) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            guard !contacts.isEmpty else {
                parent.onError("No contacts were selected from the picker.")
                parent.presentationMode.wrappedValue.dismiss()
                return
            }

            var results: [ImportedContact] = []
            for contact in contacts {
                let name = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                if let phone = contact.phoneNumbers.first?.value.stringValue {
                    results.append(ImportedContact(name: name.isEmpty ? "Unknown" : name, phoneNumber: phone))
                }
            }

            if results.isEmpty {
                parent.onError("Selected contacts did not contain valid phone numbers.")
            } else {
                parent.onContactsSelected(results)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
