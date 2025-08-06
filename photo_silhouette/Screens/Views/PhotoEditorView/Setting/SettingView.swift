//
//  InitialView.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

import SwiftUI

struct SettingView: View {
    // アプリ内課金；寄付
    @StateObject private var store = StoreManager()
    @State private var isProcessing = false
    @State private var showThankYou = false
    @State private var errorMessage: String? // Identifiable 用拡張はそのまま

    var body: some View {
        ZStack {
            List {
                // MARK: —  一般設定
                
                GeneralSettingSection()
                
                // MARK: —  アプリについて
                
                AboutSection(
                    isProcessing: $isProcessing,
                    showThankYou: $showThankYou,
                    errorMessage: $errorMessage
                )
            }
            
            
            // ② Loading オーバーレイ
            if isProcessing {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                    Text("NOTIFICATION_PROCESSING")
                        .font(.headline)
                }
                .padding(24)
                .background(Color(.systemBackground).opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 8)
            }
        }        
        // 課金処理に成功したら出すメッセージ
        .alert(
            Text("SUPPORT_THANK_YOU"),
            isPresented: $showThankYou
        ) {
            Button("OK", role: .cancel) {}
        }
        // 課金処理に失敗したら出すメッセージ
        .alert(item: $errorMessage) { msg in
            Alert(title: Text(msg))
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("NAV_TITLE_SETTINGS")
        .scrollContentBackground(.hidden)
        .background(Color("BackgroundColor"))
        // ナビゲーションバーのタイトル
        .navigationBarSetting(title: "NAVIGATION_TITLE_SETTINGS", isVisible: true)
        .environmentObject(store)
    }
}

// MARK: - プレビュー

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingView()
        }
    }
}

extension UIDevice {
    var hasDynamicIsland: Bool {
        // iPhone 14 Pro または iPhone 15 Pro系の画面サイズと特性で判定
        let screenHeight = max(UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.width)
        let screenWidth = min(UIScreen.main.bounds.size.height, UIScreen.main.bounds.size.width)
        let scale = UIScreen.main.scale

        // iPhone 14 Pro / 15 Pro (例: 393 x 852 @ 3x)
        let isDynamicIslandSize = (screenWidth == 393 && screenHeight == 852 && scale == 3.0)
        // iPhone 14 Pro Max / 15 Pro Max (例: 430 x 932 @ 3x)
        let isDynamicIslandMaxSize = (screenWidth == 430 && screenHeight == 932 && scale == 3.0)

        return isDynamicIslandSize || isDynamicIslandMaxSize
    }
}

