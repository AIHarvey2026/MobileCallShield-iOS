import SwiftUI
import Contacts
import ContactsUI

// MARK: - Models
struct AppSettingsPayload: Codable {
    let success: Bool?
    let support_email: String?
    let support_phone: String?
    let settings: AppSettingsDetails?
}

struct AppSettingsDetails: Codable {
    let app_name: String?
    let logo_url: String?
}

struct ImportedContact: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String
}

// MARK: - UIKit Contact Picker Presenter Wrapper
struct ContactPickerPresenter: UIViewControllerRepresentable {
    var onContactsSelected: ([ImportedContact]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onContactsSelected: onContactsSelected, onCancel: onCancel)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var onContactsSelected: ([ImportedContact]) -> Void
        var onCancel: () -> Void

        init(onContactsSelected: @escaping ([ImportedContact]) -> Void, onCancel: @escaping () -> Void) {
            self.onContactsSelected = onContactsSelected
            self.onCancel = onCancel
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            var results: [ImportedContact] = []
            for contact in contacts {
                let name = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                if let phone = contact.phoneNumbers.first?.value.stringValue {
                    results.append(ImportedContact(name: name.isEmpty ? "Unknown" : name, phoneNumber: phone))
                }
            }
            onContactsSelected(results)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }
    }
}

// MARK: - ContentView (Main Dashboard)
struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    
    @State private var appName: String = "Mobile Call Shield"
    @State private var supportEmail: String = ""
    @State private var supportPhone: String = ""
    @State private var isLoading: Bool = false
    @State private var showLogoutAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Logo: Shield
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "shield.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 65, height: 65)
                                .foregroundColor(.green)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        Text(appName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Configured from your database settings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        // Main Navigation Cards
                        VStack(spacing: 12) {
                            NavigationLink(destination: GuardianSettingsView(currentUserId: 1)) {
                                HStack {
                                    Image(systemName: "shield.lefthalf.filled")
                                        .foregroundColor(.green)
                                    Text("Guardian & Security Settings")
                                        .foregroundColor(.primary)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                            
                            NavigationLink(destination: ContactView()) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .foregroundColor(.green)
                                    Text("Manage Trusted Contacts")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }

                            NavigationLink(destination: CallHistoryView()) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.green)
                                    Text("Call History & Voicemails")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                            
                            NavigationLink(destination: AppSettingsView()) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundColor(.green)
                                    Text("Shield Settings")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)

                        VStack(spacing: 12) {
                            Text("Need Help?")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("Support Email")
                                    .font(.subheadline)
                                Spacer()
                                Text(supportEmail.isEmpty ? "Loading..." : supportEmail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.green)
                                Text("Support Phone")
                                    .font(.subheadline)
                                Spacer()
                                Text(supportPhone.isEmpty ? "Loading..." : supportPhone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Log Out of Mobile Call Shield?", isPresented: $showLogoutAlert) {
                Button("OK", role: .destructive) {
                    performLogout()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You are about to log out of the app.")
            }
        }
        .onAppear {
            fetchAppSettings()
        }
    }

    private func performLogout() {
        DispatchQueue.main.async {
            session.isLoggedIn = false
        }
    }

    private func fetchAppSettings() {
        isLoading = true
        guard let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/settings") else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data, error == nil else { return }
                do {
                    let decoded = try JSONDecoder().decode(AppSettingsPayload.self, from: data)
                    if let name = decoded.settings?.app_name {
                        self.appName = name
                    }
                    self.supportEmail = decoded.support_email ?? "support@mobilecallshield.com"
                    self.supportPhone = decoded.support_phone ?? "+1 (800) 555-0199"
                } catch {
                    print("❌ Failed to decode app settings: \(error)")
                    self.supportEmail = "support@mobilecallshield.com"
                    self.supportPhone = "+1 (800) 555-0199"
                }
            }
        }.resume()
    }
}

// MARK: - ContactView with Active Phone Contacts Picker
struct ContactView: View {
    @EnvironmentObject var session: SessionStore
    @State private var importedContacts: [ImportedContact] = []
    @State private var isPresentingPicker = false
    @State private var showLogoutAlert: Bool = false
    let currentUserId: Int = 1

    var body: some View {
        List {
            Section(header: Text("Actions")) {
                Button {
                    checkAndRequestPermission { granted in
                        if granted {
                            isPresentingPicker = true
                        } else {
                            print("❌ Contacts permission denied.")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.crop.badge.plus")
                            .foregroundColor(.blue)
                        Text("Select from Phone Contacts")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.plain)
            }

            Section(header: Text("Trusted Contacts List")) {
                if importedContacts.isEmpty {
                    Text("Your trusted numbers will appear here.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(importedContacts) { contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name)
                                .font(.headline)
                            Text(contact.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Trusted Contacts")
        .sheet(isPresented: $isPresentingPicker) {
            ContactPickerPresenter { selected in
                isPresentingPicker = false
                var newlyAdded: [ImportedContact] = []
                for contact in selected {
                    if !importedContacts.contains(where: { $0.phoneNumber == contact.phoneNumber }) {
                        importedContacts.append(contact)
                        newlyAdded.append(contact)
                    }
                }
                if !newlyAdded.isEmpty {
                    uploadBulkContacts(selected: newlyAdded)
                }
            } onCancel: {
                isPresentingPicker = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                    }
                    .foregroundColor(.red)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Log Out of Mobile Call Shield?", isPresented: $showLogoutAlert) {
            Button("OK", role: .destructive) {
                performLogout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You are about to log out of the app.")
        }
    }

    private func checkAndRequestPermission(completion: @escaping (Bool) -> Void) {
        let store = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)

        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, _ in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func uploadBulkContacts(selected: [ImportedContact]) {
        guard let url = URL(string: "https://mobile-call-shield.onrender.com/api/trusted-contacts/bulk") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let contactsPayload = selected.map { [
            "name": $0.name,
            "phone_number": $0.phoneNumber,
            "is_guardian": false
        ] }

        let payload: [String: Any] = [
            "userId": currentUserId,
            "contacts": contactsPayload
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = httpBody

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                    print("✅ Contacts successfully uploaded to backend!")
                }
            }
        }.resume()
    }

    private func performLogout() {
        DispatchQueue.main.async {
            session.isLoggedIn = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionStore())
}
