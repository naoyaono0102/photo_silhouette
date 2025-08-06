//
//  AboutSection.swift
//  round_photo
//
//  Created by 尾野順哉 on 2025/06/25.
//

// import StoreKit
import SwiftUI

struct AboutSection: View {
    @Environment(\.openURL) var openURL // URLオープン用
//    @EnvironmentObject private var store: StoreManager
    // 言語設定キーとバインディング★
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    
    @Binding var isProcessing: Bool
    @Binding var showThankYou: Bool
    @Binding var errorMessage: String?
        
    // 動的にリージョンを切り替える computed URL
//    private var appStoreURL: URL {
//        let region = appStoreRegion
//        let urlString = "https://apps.apple.com/\(region)/app/simple-photo-compressor/id6744837111"
//        return URL(string: urlString)!
//    }
    
//    private var appStoreRegion: String {
//        if let code = SKPaymentQueue.default().storefront?.countryCode {
//            return code.lowercased() // "jp", "us", "kr" など
//        }
//        // フォールバック
//        return Locale.current.region?.identifier.lowercased() ?? "us"
//    }
    
    var body: some View {
        Section(header: Text("ABOUT_APP")) {
            // MARK: — ご意見・ご要望
            
            Button(action: {
                // subject の文字列を URL エンコードする
                let subject = NSLocalizedString("FEEDBACK_SUBJECT", comment: "")
                if let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   
                   let url = URL(string: "mailto:naoya.ono.app@gmail.com?subject=\(encodedSubject)") {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "envelope")
                        .frame(width: 25)
                    Text("FEEDBACK")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .foregroundStyle(.primary)
            
            // MARK: —  プライバシーポリシー
            
            Button(action: {
                if let url = URL(string: "https://apps.seeds-digital.com/privacy-policy/") {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "shield.righthalf.filled")
                        .frame(width: 25)
                    Text("PRIVACY_POLICY")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .foregroundStyle(.primary)
            
            // MARK: — 開発者の他のアプリ
            
            Button(action: {
                // 言語コードが "ja" のとき日本ページ、それ以外は US ページへ
                let urlString = if Locale.current.language.languageCode?.identifier == "ja" {
                    "https://apps.apple.com/jp/developer/mitsuko-margot-kubota-ono/id1799524637"
                } else {
                    "https://apps.apple.com/us/developer/mitsuko-margot-kubota-ono/id1799524637"
                }
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            }) {
                HStack {
                    Image(systemName: "apps.iphone")
                        .frame(width: 25)
                    Text("MORE_APPS_BY_DEVELOPER")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .foregroundStyle(.primary)
            
            // MARK: — レビューを書く
            
            Button {
                // 自分の App Store 上のアプリID に書き換えてください
                let appID = "6749043567"
                let urlString = "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            } label: {
                HStack {
                    Image(systemName: "star.bubble")
                        .frame(width: 25)
                    Text("WRITE_REVIEW")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .foregroundStyle(.primary)
            
            // アプリの共有
//            ShareLink(item: appStoreURL) {
//                HStack {
//                    Image(systemName: "square.and.arrow.up")
//                        .frame(width: 25)
//                    Text("SHARE_APP")
//                }
//                .foregroundStyle(.primary)
//            }
//            .foregroundStyle(.primary)
            
            // 「開発者を支援する」ボタン（ダイアログなしで直接課金）
//            Button {
//                isProcessing = true
//                Task {
//                    defer { isProcessing = false }
//
//                    // ① いつでも最新の製品情報をロード
//                    await store.loadProducts()
//
//                    // 取得できなければエラー表示
//                    guard let product = store.products.first else {
//                        errorMessage = NSLocalizedString("NO_IAP_PRODUCTS", comment: "")
//                        isProcessing = false
//                        return
//                    }
//
//                    // ③ 購入処理
//                    await doPurchase(product)
//                }
//            } label: {
//                HStack {
//                    Image(systemName: "heart")
//                        .frame(width: 25)
//                    Text("SUPPORT_DEVELOPER")
//                    Spacer()
//                    // 価格表示もあっても良い
//                    Text(store.products.first?.displayPrice ?? "")
//                        .foregroundColor(.secondary)
//                }
//            }
//            .foregroundStyle(.primary)
//            .disabled(isProcessing)
        }
        .textCase(nil)
    }
    
    // MARK: — 購入処理
    
//    private func doPurchase(_ product: Product) async {
//        defer { isProcessing = false }
//
//        do {
//            try await store.purchase(product)
//            // 成功時はフラグだけ立てる
//            showThankYou = true
//        }
//        catch StoreManager.PurchaseError.cancelled {
//            // キャンセル時は何もしない
//        }
//        catch {
//            // それ以外は errorMessage に文字列を入れる
//            errorMessage = error.localizedDescription
//        }
//    }
}

#Preview {
    // Section は List の中でしか描画されないので、List で囲みます
    List {
        AboutSection(
            isProcessing: .constant(false),
            showThankYou: .constant(false),
            errorMessage: .constant(nil)
        )
    }
    // StoreManager を @EnvironmentObject で渡す
    .environmentObject(StoreManager())
}

// ファイルの末尾あたりに追加
extension String: Identifiable {
    public var id: String { self }
}
