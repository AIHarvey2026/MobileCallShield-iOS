import SwiftUI
import Contacts
import ContactsUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var contactName: String = ""
    @State private var phoneNumber: String = ""
    @State private var showContactPicker: Bool = false
    @State private var availableNumbers: [String] = []
    @State private var showNumberPickerAlert: Bool = false
    @State private var selectedNameFromPicker: String = ""
    
    @State private var isSaving: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                TextField("Contact Name", text: $contactName)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                
                Button(action: {
                    showContactPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .foregroundColor(.blue)
                        Text("Import from Phone Contacts")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section {
                Button(action: {
                    saveContact()
                }) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Trusted Contact")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(contactName.isEmpty || phoneNumber.isEmpty || isSaving)
            }
        }
        .navigationTitle("Add Trusted Contact")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { name, numbers in
                if numbers.count == 1 {
                    self.contactName = name
                    self.phoneNumber = numbers[0]
                } else if numbers.count > 1 {
                    self.selectedNameFromPicker = name
                    self.availableNumbers = numbers
                    self.showNumberPickerAlert = true
                }
            }
        }
        .confirmationDialog("Select Phone Number for \(selectedNameFromPicker)", isPresented: $showNumberPickerAlert, titleVisibility: .visible) {
            ForEach(availableNumbers, id: \.self) { number in
                Button(number) {
                    self.contactName = selectedNameFromPicker
                    self.phoneNumber = number
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Status", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveContact() {
        isSaving = true
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/contacts") else {
            isSaving = false
            alertMessage = "Invalid backend URL."
            showAlert = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "name": contactName,
            "phoneNumber": phoneNumber
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSaving = false
                if error != nil {
                    alertMessage = "Failed to save contact to backend."
                } else {
                    alertMessage = "Contact added successfully!"
                }
                showAlert = true
            }
        }.resume()
    }
}

// MARK: - UIKit Contact Picker Bridge
struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: (String, [String]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var onSelect: (String, [String]) -> Void

        init(onSelect: @escaping (String, [String]) -> Void) {
            self.onSelect = onSelect
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let numbers = contact.phoneNumbers.map { $0.value.stringValue }
            onSelect(name, numbers)
        }
    }
}
