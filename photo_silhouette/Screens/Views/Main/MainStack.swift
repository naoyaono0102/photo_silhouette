//
//  InitialView.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

import SwiftUI

struct MainStack: View {
    @State private var navigationPath: [NavigationItem] = []

    var body: some View {
        VStack(spacing: 0) {
            NavigationStack(path: $navigationPath) {
                // 遷移元の画面：ホーム画面
                GalleryView(navigationPath: $navigationPath)
                    // 画面遷移の定義
                    .navigationDestination(for: NavigationItem.self) { item in
                        switch item.id {
                        case .SETTING:
                            SettingView()
                        case .PHOTO_EDITOR:
                            // ここで PHAsset か UIImage が item に格納されているので、
                            // PhotoEditorView を呼び出す
                            if let pickedAsset = item.asset {
                                // アルバムから選んだ Asset で遷移する場合
                                PhotoEditorView(asset: pickedAsset)
                            } else if let pickedImage = item.capturedUIImage {
                                // カメラ撮影直後の UIImage で遷移する場合
                                PhotoEditorView(capturedUIImage: pickedImage)
                            } else {
                                // 両方とも nil の場合は EmptyView など
                                EmptyView()
                            }
                        default:
                            EmptyView()
                        }
                    }
            }

            // 広告ビュー
//            BannerContentView()
//                .background(Color("BackgroundColor"))
//                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

#Preview {
    MainStack()
}
