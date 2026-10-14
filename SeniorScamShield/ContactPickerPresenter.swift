import SwiftUI
import Contacts
import ContactsUI

class ContactPickerCoordinator: NSObject, CNContactPickerDelegate {
    var onContactsSelected: ([ImportedContact]) -> Void
    var onCancel: () -> Void

    init(onContactsSelected: @escaping ([ImportedContact]) -> Void, onCancel: @escaping () -> Void) {
        self.onContactsSelected = onContactsSelected
        self.onCancel = onCancel
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
        print("✅ ContactPicker: User selected \(contacts.count) raw contact(s).")
        var results: [ImportedContact] = []
        for contact in contacts {
            let name = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
            if let phone = contact.phoneNumbers.first?.value.stringValue {
                results.append(ImportedContact(name: name.isEmpty ? "Unknown" : name, phoneNumber: phone))
            } else {
                print("⚠️ ContactPicker: Skipped contact '\(name)' because no phone number was found.")
            }
        }
        onContactsSelected(results)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        print("⚠️ ContactPicker: User cancelled the picker sheet.")
        onCancel()
    }
}

extension View {
    func presentContactPicker(isPresented: Binding<Bool>, onContactsSelected: @escaping ([ImportedContact]) -> Void) -> some View {
        self.onChange(of:isPresented.wrappedValue) { newValue in
            print("🔍 ContactPicker Modifier: isPresented changed to \(newValue)")
            if newValue {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    print("❌ ContactPicker Error: Could not find active UIWindowScene.")
                    isPresented.wrappedValue = false
                    return
                }
                
                guard let rootViewController = windowScene.windows.first?.rootViewController else {
                    print("❌ ContactPicker Error: Could not find rootViewController from windowScene.windows.")
                    isPresented.wrappedValue = false
                    return
                }

                print("ℹ️ ContactPicker: Successfully acquired rootViewController: \(type(of: rootViewController))")

                let picker = CNContactPickerViewController()
                let coordinator = ContactPickerCoordinator { contacts in
                    onContactsSelected(contacts)
                    isPresented.wrappedValue = false
                } onCancel: {
                    isPresented.wrappedValue = false
                }

                picker.delegate = coordinator
                objc_setAssociatedObject(picker, &AssociatedKey.coordinatorKey, coordinator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                // Check if rootViewController is already presenting something else
                if rootViewController.presentedViewController != nil {
                    print("⚠️ ContactPicker Warning: rootViewController is already presenting another view controller! This can block presentation.")
                }

                rootViewController.present(picker, animated: true) {
                    print("🚀 ContactPicker: Present animation completed successfully.")
                }
            }
        }
    }
}

private struct AssociatedKey {
    static var coordinatorKey = "coordinatorKey"
}
