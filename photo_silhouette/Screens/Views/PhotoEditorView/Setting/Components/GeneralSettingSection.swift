//
//  GeneralSettingSection.swift
//  round_photo
//
//  Created by 尾野順哉 on 2025/06/25.
//

import SwiftUI

struct GeneralSettingSection: View {
    // 言語設定キーとバインディング★
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    // 外観モード
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    
    // 設定画面 言語選択時に表示するラベルを返す
    // 設定画面 言語選択時に表示するラベルを返す
    private func labelForLanguage(_ code: String) -> String {
        switch code {
        case "en":
            return NSLocalizedString("LANGUAGE_ENGLISH", comment: "")
        case "ja":
            return NSLocalizedString("LANGUAGE_JAPANESE", comment: "")
        case "ko":
            return NSLocalizedString("LANGUAGE_KOREAN", comment: "")
        case "zh-Hans":
            return NSLocalizedString("LANGUAGE_CHINESE_SIMPLIFIED", comment: "")
        case "zh-Hant":
            return NSLocalizedString("LANGUAGE_CHINESE_TRADITIONAL", comment: "")
        case "fr":
            return NSLocalizedString("LANGUAGE_FRENCH", comment: "")
        case "es":
            return NSLocalizedString("LANGUAGE_SPANISH", comment: "")
        case "pt-BR":
            return NSLocalizedString("LANGUAGE_PORTUGUESE_BRAZIL", comment: "")
        case "pt-PT":
            return NSLocalizedString("LANGUAGE_PORTUGUESE_PORTUGAL", comment: "")
        case "ru":
            return NSLocalizedString("LANGUAGE_RUSSIAN", comment: "")
        case "id":
            return NSLocalizedString("LANGUAGE_INDONESIAN", comment: "")
        case "th":
            return NSLocalizedString("LANGUAGE_THAI", comment: "")
        case "hi":
            return NSLocalizedString("LANGUAGE_HINDI", comment: "")
        case "ar":
            return NSLocalizedString("LANGUAGE_ARABIC", comment: "")
        case "vi":
            return NSLocalizedString("LANGUAGE_VIETNAMESE", comment: "")
        case "ms":
            return NSLocalizedString("LANGUAGE_MALAY", comment: "")
        case "es-419":
            return NSLocalizedString("LANGUAGE_SPANISH_LATIN", comment: "")
        case "es-US":
            return NSLocalizedString("LANGUAGE_SPANISH_US", comment: "")
        case "fr-CA":
            return NSLocalizedString("LANGUAGE_FRENCH_CANADA", comment: "")
        default:
            return NSLocalizedString("LANGUAGE_SYSTEM", comment: "")
        }
    }
    
    // Picker に渡す全言語リスト（system は先頭、他は表示名順）
    private var sortedLanguageItems: [(code: String, key: String)] {
        let items: [(String, String)] = [
            ("system",   "LANGUAGE_SYSTEM"),
            ("en",       "LANGUAGE_ENGLISH"),
            ("ja",       "LANGUAGE_JAPANESE"),
            ("ko",       "LANGUAGE_KOREAN"),
            ("zh-Hans",  "LANGUAGE_CHINESE_SIMPLIFIED"),
            ("zh-Hant",  "LANGUAGE_CHINESE_TRADITIONAL"),
            ("fr",       "LANGUAGE_FRENCH"),
            ("fr-CA",    "LANGUAGE_FRENCH_CANADA"),
            ("es",       "LANGUAGE_SPANISH"),
            ("es-419",   "LANGUAGE_SPANISH_LATIN"),
            ("es-US",    "LANGUAGE_SPANISH_US"),
            ("pt-BR",    "LANGUAGE_PORTUGUESE_BRAZIL"),
            ("pt-PT",    "LANGUAGE_PORTUGUESE_PORTUGAL"),
            ("ru",       "LANGUAGE_RUSSIAN"),
            ("id",       "LANGUAGE_INDONESIAN"),
            ("ms",       "LANGUAGE_MALAY"),
            ("th",       "LANGUAGE_THAI"),
            ("hi",       "LANGUAGE_HINDI"),
            ("ar",       "LANGUAGE_ARABIC"),
            ("vi",       "LANGUAGE_VIETNAMESE")
        ]
        
        let head = items[0]
        let tail = items.dropFirst().sorted { lhs, rhs in
            let l = NSLocalizedString(lhs.1, comment: "")
            let r = NSLocalizedString(rhs.1, comment: "")
            return l < r
        }
        return [head] + tail
    }
    
    // 表示用ラベルを返すヘルパー
    private func labelForAppearance(_ code: String) -> String {
        switch code {
        case "light": return NSLocalizedString("APPEARANCE_LIGHT", comment: "")
        case "dark": return NSLocalizedString("APPEARANCE_DARK", comment: "")
        default: return NSLocalizedString("APPEARANCE_SYSTEM", comment: "")
        }
    }
    
    var body: some View {
        Section(header: Text("GENERAL_SETTINGS")) {
            // 言語設定
//            Menu {
//                ForEach(sortedLanguageItems, id: \.code) { item in
//                    Button(action: { appLanguage = item.code }) {
//                        Label(
//                            NSLocalizedString(item.key, comment: ""),
//                            systemImage: appLanguage == item.code ? "checkmark" : ""
//                        )
//                    }
//                }
//            } label: {
//                HStack {
//                    Image(systemName: "globe")
//                        .frame(width: 25)
//                    Text("LANGUAGE_SETTINGS")
//                    
//                    Spacer()
//                    
//                    // 現在の選択を表示
//                    Text(labelForLanguage(appLanguage))
//                        .foregroundColor(.secondary)
//                }
//                .foregroundColor(.primary)
//                .contentShape(Rectangle())
//            }
            
            // 外観モード
            Menu {
                Button { appAppearance = "system" } label: {
                    Label("APPEARANCE_SYSTEM", systemImage: appAppearance == "system" ? "checkmark" : "")
                }
                Button { appAppearance = "light" } label: {
                    Label("APPEARANCE_LIGHT", systemImage: appAppearance == "light" ? "checkmark" : "")
                }
                Button { appAppearance = "dark" } label: {
                    Label("APPEARANCE_DARK", systemImage: appAppearance == "dark" ? "checkmark" : "")
                }
            } label: {
                HStack {
                    Image(systemName: "circle.lefthalf.fill")
                        .frame(width: 25)
                    Text("APPEARANCE_SETTINGS")
                        .foregroundColor(.primary)
                    Spacer()
                    Text(labelForAppearance(appAppearance))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
                .contentShape(Rectangle())
            }
        }
        .textCase(nil)
    }
}

#Preview {
    List {
        GeneralSettingSection()
    }
}
