
import Foundation
import StoreKit
import Combine // <--- Add this import

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isSubscribed: Bool = false
    @Published var product: Product? = nil
    
    // Replace with your App Store Connect Product ID
    private let productId = "com.mobilecallshield.monthly"
    
    init() {
        Task {
            await fetchProduct()
            await updateSubscriptionStatus()
        }
    }
    
    func fetchProduct() async {
        do {
            let products = try await Product.products(for: [productId])
            self.product = products.first
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    func purchase() async -> Bool {
        guard let product = product else { return false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            return false
        }
    }
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == productId {
                    // Check if subscription or 14-day trial is active
                    if transaction.revocationDate == nil {
                        self.isSubscribed = true
                        // Send updated status to backend
                        await syncSubscriptionWithBackend(transaction: transaction)
                        return
                    }
                }
            }
        }
        self.isSubscribed = false
    }
    
    private func syncSubscriptionWithBackend(transaction: Transaction) async {
        let userId = UserDefaults.standard.integer(forKey: "loggedInUserId")
        guard userId > 0, let url = URL(string: "https://mobilecallshield-backend.onrender.com/api/subscription/sync") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "originalTransactionId": String(transaction.originalID),
            "expirationDate": transaction.expirationDate?.timeIntervalSince1970 ?? 0,
            "isTrial": transaction.offerType == .introductory
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
}
