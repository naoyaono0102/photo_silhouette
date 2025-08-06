//
//  AdmobManager.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/29.
//

import GoogleMobileAds
import UIKit
import UserMessagingPlatform

enum AdmobManager {
    static func configure() {
        Task {
            await setupAdmobIfNeeded()
        }
    }

    private static func setupAdmobIfNeeded() async {
        print("=== setupAdmobIfNeeded ===")
        do {
            try await presentFormIfPossible()
            await setupAdmob()
        } catch {
            print(error.localizedDescription)
        }
    }

    private static func presentFormIfPossible() async throws {
        print("=== presentFormIfPossible ===")

        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        // リクエストの完了を待つ
        try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)

        // formStatus の状態を確認
        let formStatus = ConsentInformation.shared.formStatus
        if formStatus != .available {
            // 状態が利用できない場合の処理
            print("Error: formStatus is not available: \(formStatus)")
            throw UMPError.formStatusIsNotAvailable(formStatus)
        }

        // フォームが利用可能なら、広告リクエストを行う
        try await loadAndPresentIfPossible()

        if ConsentInformation.shared.canRequestAds == false {
            print("Error cannotRequestAds")
            throw UMPError.cannotRequestAds
        }
    }

//    private static func presentFormIfPossible() async throws {
//        print("=== presentFormIfPossible ===")
//
//        let parameters = RequestParameters()
//
//        // EU外のユーザーには同意フォームを表示しない
//        let isEUUser = isEUUser()
//
//        if !isEUUser {
//            print("Non-EU user, skipping consent form.")
//            // EU外ユーザーの場合は formStatus に関係なく setupAdmob を実行
//            await setupAdmob()
//            return
//        }
//
//        parameters.isTaggedForUnderAgeOfConsent = false
//
//        // 同意情報の更新をリクエストし、その完了を待つ
//        try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
//
//        // formStatusの状態を確認
//        let formStatus = ConsentInformation.shared.formStatus
//        if formStatus != .available {
//            print("Error: formStatus is not available: \(formStatus.rawValue)")
//            // ここでエラーを投げないようにする
//            // もし formStatus が利用不可でも、setupAdmob を呼び出す
//            await setupAdmob()
//            return
//        }
//
//        // フォームが利用可能なら、広告リクエストを行う
//        try await loadAndPresentIfPossible()
//
//        if ConsentInformation.shared.canRequestAds == false {
//            print("Error cannotRequestAds")
//            throw UMPError.cannotRequestAds
//        }
//
//        // 広告設定の初期化処理
//        await setupAdmob()
//    }

//    private static func isEUUser() -> Bool {
//        // ユーザーの地域がEUかどうかを判定するロジック
//        return Locale.current.regionCode == "EU"
//    }

    @MainActor
    private static func loadAndPresentIfPossible() async throws {
        print("loadAndPresentIfPossible")
        guard let rootViewController = UIApplication.shared.rootViewController else {
            print("Error cannotGetRootViewController")
            throw UMPError.cannotGetRootViewController
        }
        try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
    }

    private static func setupAdmob() async {
        print("=== set up admob ===")
        // モバイル広告の初期化
        MobileAds.shared.start { status in
            // Optional: Log each adapter's initialization latency.
            let adapterStatuses = status.adapterStatusesByClassName
            for adapter in adapterStatuses {
                let adapterStatus = adapter.value
                NSLog("Adapter Name: %@, Description: %@, Latency: %f", adapter.key,
                      adapterStatus.description, adapterStatus.latency)
            }
            // 広告の読み込みを開始
        }

        // テストデバイスIDを設定
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "C7D6BD29-290C-44DB-BCFA-25670BDDFB88" // your test device id
        ]

        print("テストデバイスID設定完了")
    }

    private enum UMPError: Error {
        /// formStatus が available ではない
        case formStatusIsNotAvailable(_ formStatus: FormStatus)
        /// ads をリクエストできない
        case cannotRequestAds
        /// rootViewController を取得できない
        case cannotGetRootViewController
    }
}

extension UIApplication {
    var rootViewController: UIViewController? {
        // 複数のシーンがある場合、最初の UIWindowScene を使う例
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController
    }
}
