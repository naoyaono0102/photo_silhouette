//
//  StoreManager.swift
//  video_to_audio
//
//  Created by 尾野順哉 on 2025/06/20.
//

// StoreManager.swift
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    let productIDs = ["CirclePhotoDonation"]
    
    enum PurchaseError: Error {
        case cancelled
        case pending
    }
    
    /// 読み込んだ Product 情報
    @Published var products: [Product] = []
    
    init() { Task { await loadProducts() } }
    
    /// App Store から製品情報を取得
    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)
            print("🛒 fetched:", fetched.map(\.id))
            products = fetched
        } catch {
            print("🛒 failed to load:", error)
        }
    }
    
    /// 購入処理
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
        case .userCancelled:
            throw PurchaseError.cancelled
        case .pending:
            throw PurchaseError.pending
        @unknown default:
            throw PurchaseError.pending
        }
    }
        
    /// StoreKit2 の検証ラッパー
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified(_, let err): throw err
        }
    }
}
