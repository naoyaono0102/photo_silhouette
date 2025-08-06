//
//  photo_silhouetteApp.swift
//  photo_silhouette
//
//  Created by 尾野順哉 on 2025/08/06.
//

import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
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
        
        return true
    }
}

@main
struct photo_silhouetteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 言語設定 "system" = 端末設定, "en" = English, "ja" = 日本語
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    // 外観モード
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    
    
    var body: some Scene {
        WindowGroup {
            InitialView()
            // ここで外観モードを適用
                .preferredColorScheme({
                    switch appAppearance {
                    case "light": return .light
                    case "dark": return .dark
                    default: return nil
                    }
                }())
            // ★Locale 環境を override★
            // system のときは自動更新ロケール、それ以外は固定
                .environment(\.locale,
                              appLanguage == "system"
                              ? .autoupdatingCurrent
                              : Locale(identifier: appLanguage))
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                            // リクエスト後の状態に応じた処理を行う
                            switch status {
                            case .authorized:
                                print("Authorized")
                            case .denied:
                                print("denied")
                            case .notDetermined:
                                print("Not Determined")
                            case .restricted:
                                print("Restricted")
                            @unknown default:
                                print("Unknown")
                            }
                        })
                    }
                }
            // #if DEBUG
            //                .overlay(
            //                    Button(action: {
            //                        // 広告インスペクタを表示
            //                        // 初期ビューがボタンを押すことでインスペクタを呼び出します
            //                        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            //                            MobileAds.shared.presentAdInspector(from: rootViewController) { error in
            //                                if let error {
            //                                    print("広告インスペクタの表示に失敗しました: \(error.localizedDescription)")
            //                                } else {
            //                                    print("広告インスペクタが正常に表示されました")
            //                                }
            //                            }
            //                        }
            //                    }) {
            //                        Text("広告インスペクタを表示")
            //                            .padding()
            //                            .background(Color.blue)
            //                            .foregroundColor(.white)
            //                            .cornerRadius(10)
            //                    }
            //                    .padding(.top, 50), alignment: .top
            //                )
            // #endif
        }
    }
}

