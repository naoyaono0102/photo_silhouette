//
//  InitialView.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

// import AppTrackingTransparency
import SwiftUI

struct InitialView: View {
    @State private var isInitialized: Bool = false

    var body: some View {
        ZStack {
            if isInitialized {
                MainStack()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("BackgroundColor"))
            }
        }
        .onAppear {
            // 初期化用のディレイを入れる（例: 1秒後にMainStackへ遷移）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isInitialized = true
            }

            // 使えるフォントの確認処理
//            for family in UIFont.familyNames.sorted() {
//                print("📂 \(family)")
//                for name in UIFont.fontNames(forFamilyName: family) {
//                    print("   🎯 \(name)")
//                }
//            }
        }
    }
}

struct InitialView_Previews: PreviewProvider {
    static var previews: some View {
        InitialView()
    }
}
