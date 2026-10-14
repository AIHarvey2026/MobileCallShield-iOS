import SwiftUI

struct MainDashboardView: View {
    @Binding var isLoggedIn: Bool
    
    // Check if the authenticated user has an admin role
    @AppStorage("userRole") private var userRole: String = "user"
    @AppStorage("isAdmin") private var isAdmin: Bool = false
    
    @State private var showLogoutAlert: Bool = false
    @State private var isPulsing: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Pulsing Active Protection Shield Logo
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(isPulsing ? 1.3 : 1.0)
                            .opacity(isPulsing ? 0.2 : 0.8)
                        
                        Circle()
                            .fill(Color.green.opacity(0.3))
                            .frame(width: 95, height: 95)
                        
                        Image(systemName: "shield.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.green)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(height: 150)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            isPulsing = true
                        }
                    }
                    
                    Text("Protection Active")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Your device is actively guarded against scam calls.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Main Navigation Cards / Buttons
                    VStack(spacing: 16) {
                        NavigationLink(destination: ContactView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "person.2.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                Text("Trusted Contacts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                        
                        // Shield Settings Card (Protected by Guardian PIN)
                        NavigationLink(destination: AppSettingsView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                Text("Shield Settings")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        }
                        
                        // Admin Control Panel (Hidden UNLESS logged-in user is Admin)
                        if isAdmin || userRole.lowercased() == "admin" {
                            NavigationLink(destination: AdminDashboardView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "gearshape.2.fill")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                    Text("Admin Control Panel")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            // Toolbar properly bound to the NavigationStack context
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
                Text("You are about to log out of the app. You will no longer be protected by Mobile Call Shield until you log back in.")
            }
        }
    }

    private func performLogout() {
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
        }
        isLoggedIn = false
    }
}
