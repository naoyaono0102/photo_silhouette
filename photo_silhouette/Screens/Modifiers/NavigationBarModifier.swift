//
//  NavigationBarModifier.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

import SwiftUI

enum NavigationBarIconPosition {
    case leading, trailing
}

// MARK: - 基本設定

// ナビゲーションバーオプション
struct NavigationBarOptions {
    var title: String?
    let isVisible: Bool
}

/// ナビゲーションバーモディファイア
private struct NavigationBarModifier: ViewModifier {
    let options: NavigationBarOptions

    init(options: NavigationBarOptions) {
        self.options = options

        // ナビゲーションバーの外観を設定
        setAppearance()
    }

    func body(content: Content) -> some View {
        let title = options.title ?? ""
        let isShowNavigationBar = options.isVisible

        content
            .navigationBarTitleDisplayMode(.inline) // タイトルの表示モード
            .navigationTitle(LocalizedStringKey(title)) // 表示するタイトル
            .navigationBarHidden(isShowNavigationBar ? false : true) // 表示・非表示設定
            .accentColor(Color("BackButtonColor")) // 戻るボタンの色を変える
    }

    // ナビゲーションバーの外観を設定
    private func setAppearance() {
        let navBarAppearance = UINavigationBarAppearance()

        // 背景色
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(named: "NavigationHeaderColor")

        // 下線の色
        navBarAppearance.shadowColor = .clear

        // タイトルの色
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(named: "NavigationTextColor") ?? UIColor.black]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "NavigationTextColor") ?? UIColor.black]

        // 戻るボタンの文字色
        let backItemAppearance = UIBarButtonItemAppearance()
        backItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]

        // 文字を非表示にしたい場合は.clear
        navBarAppearance.backButtonAppearance = backItemAppearance

        // 戻るボタンの画像・アイコン・色
        let backButtonImage = UIImage(systemName: "chevron.backward")?.withTintColor(UIColor(named: "NavigationIconColor") ?? UIColor.black, renderingMode: .alwaysOriginal)
        navBarAppearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)

        // 設定を適用
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .black // 戻る「<」ボタンの色
    }
}

// ビューの拡張
extension View {
    // ナビゲーションバーの設定
    func navigationBarSetting(title: String, isVisible: Bool) -> some View {
        modifier(NavigationBarModifier(options: .init(title: title, isVisible: isVisible)))
    }
}

//////////////////////////////////////////////////////////////////////////////////////////////

// MARK: - アイコン設定

//////////////////////////////////////////////////////////////////////////////////////////////
// アイコンオプション
struct NavigationBarIconOptions {
    let name: String // アイコン名
    let isEnabled: Bool // アイコンの有効判定
    let iconPosition: NavigationBarIconPosition // 左か右
    let action: () -> Void
}

// アイコンモディファイア
private struct NavigationBarIconModifier: ViewModifier {
    let options: NavigationBarIconOptions

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: options.iconPosition == .leading ? .navigationBarLeading : .navigationBarTrailing) {
                    Button(action: options.action,
                           label: {
                               Image(systemName: options.name)
                                   .foregroundStyle(options.isEnabled ? Color("NavigationIconColor") : .gray) // アイコンカラー
                           })
                           .disabled(!options.isEnabled)
                }
            }
    }
}

// ビューの拡張
extension View {
    // ナビゲーションバーの設定
    func navigationBarIconSetting(
        name: String,
        isEnabled: Bool = true,
        iconPosition: NavigationBarIconPosition = .trailing,
        action: @escaping () -> Void
    ) -> some View {
        modifier(
            NavigationBarIconModifier(
                options: .init(
                    name: name,
                    isEnabled: isEnabled,
                    iconPosition: iconPosition,
                    action: action
                )
            )
        )
    }
}

#Preview {
    NavigationView {
        Text("Hello world")
            .navigationBarSetting(title: "HOME", isVisible: true)
            .navigationBarIconSetting(name: "folder.fill", isEnabled: true, action: {})
    }
}
