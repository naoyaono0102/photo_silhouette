//
//  EditorViewModel.swift
//  white_frame
//
//  Created by 尾野順哉 on 2025/07/11.
//

import Foundation
import SwiftUI

class EditorViewModel: ObservableObject {
    // 元画像は必ず保持しておく
    @Published var originalImage: UIImage?
    @Published var selectedFilter: FilterType = .none
    
    // レイアウト
    @Published var selectedLayout: FrameLayout = .mini
    // カラー
    @Published var colorMode: ColorMode = .simple
    @Published var selectedSimpleColor: Color = .white
    @Published var selectedGradient: [Color] = [.red, .orange]
    // 日付
    @Published var selectedDate: Date = .init()
    @Published var isDateVisible: Bool = true
    @Published var dateColor: Color = .orange
    
    init(image: UIImage? = nil) {
        self.originalImage = image
    }
    
    let pictureSizes: [FrameLayout: CGSize] = [
        .mini: CGSize(width: 46, height: 62),
        .square: CGSize(width: 62, height: 62),
        .wide: CGSize(width: 99, height: 62)
    ]
    let frameSizes: [FrameLayout: CGSize] = [
        .mini: CGSize(width: 54, height: 86),
        .square: CGSize(width: 72, height: 86),
        .wide: CGSize(width: 108, height: 86)
    ]
    
    var dateUIColor: UIColor {
        UIColor(dateColor)
    }

    /// 選択中フィルターをかけた画像を返す
    var filteredImage: UIImage? {
        guard let img = originalImage else { return nil }
        guard let name = selectedFilter.ciName else { return img }
        let ciImage = CIImage(image: img)
        let filter = CIFilter(name: name)
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
            
        // ← この switch 文の中で定数を書き換え
        switch selectedFilter {
        case .bloom:
            // デフォルトは intensity=1.0, radius=10.0
            filter?.setValue(0.8, forKey: kCIInputIntensityKey)
            filter?.setValue(12.0, forKey: kCIInputRadiusKey)
            
        case .pixellate:
            // デフォルトは scale=8.0
            filter?.setValue(10.0, forKey: kCIInputScaleKey)
            
        case .sepia:
            // デフォルトは intensity=1.0
            filter?.setValue(0.9, forKey: kCIInputIntensityKey)

        default:
            break
        }
        
        // 特定のフィルターのパラメーター
        
        let context = CIContext()
        if let output = filter?.outputImage,
           let cgimg = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgimg, scale: img.scale, orientation: img.imageOrientation)
        }
        return img
    }
    
    /// 保存用の最終合成画像を返す
    var composedImage: UIImage? {
        guard let img = filteredImage else { return nil }
        let frameSize = frameSizes[selectedLayout]! // もともとのレイアウト サイズ
        // 1. まず白フレーム背景を描画
        let renderer = UIGraphicsImageRenderer(size: frameSize)
        return renderer.image { ctx in
            // 白いフレーム
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: frameSize))
            
            // フィルタ済み写真をフレーム内に中央配置
            let picSize = pictureSizes[selectedLayout]!
            let scale = min(frameSize.width / picSize.width, frameSize.height / picSize.height)
            let drawSize = CGSize(width: picSize.width * scale, height: picSize.height * scale)
            let origin = CGPoint(
                x: (frameSize.width - drawSize.width) / 2,
                y: (frameSize.height - drawSize.height) / 2
            )
            img.draw(in: CGRect(origin: origin, size: drawSize))
            
            // 日付
            if isDateVisible {
                let str = DateFormatter.chekiStyle.string(from: selectedDate)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "DS-Digital-Bold", size: 18)!,
                    .foregroundColor: UIColor.orange
                ]
                
//                Text(vm.selectedDate.chekiStyleDateString)
//                //                            .font(.custom("DS-Digital-Italic", size: 18))
//                    .font(.custom("DS-Digital-Bold", size: 18))
//                    .foregroundColor(.orange)
//                    .padding(.bottom, 8)
//                    .padding(.trailing, 8)
                
                let textSize = str.size(withAttributes: attrs)
                let pt = CGPoint(
                    x: frameSize.width - textSize.width - 8,
                    y: frameSize.height - textSize.height - 8
                )
                str.draw(at: pt, withAttributes: attrs)
            }
        }
    }
    
    /// プレビューと同じ見た目で1枚絵を生成する
    func snapshotImage(
        layout: FrameLayout,
        colorMode: ColorMode,
        simpleColor: Color,
        gradient: [Color],
        filtered: UIImage?,
        date: Date,
        isDateVisible: Bool,
        zoomScale: CGFloat,
        panOffset: CGSize
    ) -> UIImage? {
        guard let img = filtered else { return nil }
        
        let frameSize = frameSizes[layout]! // レイアウトごとの白フレーム全体サイズ
        let picSize = pictureSizes[layout]! // レイアウトごとの写真エリアサイズ
        
        // 描画コンテキスト準備
        let renderer = UIGraphicsImageRenderer(size: frameSize)
        return renderer.image { ctx in
            // 1) フレーム背景（シンプル or グラデーション）
            if colorMode == .simple {
                UIColor(simpleColor).setFill()
                ctx.fill(CGRect(origin: .zero, size: frameSize))
            } else {
                // 簡易グラデーション描画
                let uiColors = gradient.map { UIColor($0) }
                let cgColors = uiColors.map { $0.cgColor } as CFArray
                let space = CGColorSpaceCreateDeviceRGB()
                let grad = CGGradient(colorsSpace: space, colors: cgColors, locations: nil)!
                ctx.cgContext.drawLinearGradient(
                    grad,
                    start: .zero,
                    end: CGPoint(x: frameSize.width, y: frameSize.height),
                    options: []
                )
            }
            
            // 2) フィルター済み写真を「ズーム×パン」付きで描画
            let fitScale = min(frameSize.width / picSize.width,
                               frameSize.height / picSize.height)
            let drawSize = CGSize(
                width: picSize.width * fitScale * zoomScale,
                height: picSize.height * fitScale * zoomScale
            )
            let origin = CGPoint(
                x: (frameSize.width - drawSize.width) / 2 + panOffset.width,
                y: (frameSize.height - drawSize.height) / 2 + panOffset.height
            )
            img.draw(in: CGRect(origin: origin, size: drawSize))
            
            // 3) 日付をチェキ風フォントで描画
            if isDateVisible {
                let str = DateFormatter.chekiStyle.string(from: date)
                // フォントはロードされた DS‑DIGI を使う or 等幅フォールバック
                let font = UIFont(name: "DS-DIGI", size: 14)
                    ?? UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.orange
                ]
                let textSize = str.size(withAttributes: attrs)
                let pt = CGPoint(
                    x: frameSize.width - textSize.width - 8,
                    y: frameSize.height - textSize.height - 8
                )
                str.draw(at: pt, withAttributes: attrs)
            }
        }
    }
}

enum FrameLayout: String, CaseIterable, Identifiable {
    case mini, square, wide
    var id: Self { self }
    var title: String {
        switch self {
        case .mini: return "mini"
        case .square: return "square"
        case .wide: return "wide"
        }
    }
}

enum ColorMode: String, CaseIterable, Identifiable {
    case simple, gradient
    var id: Self { self }
    var title: String { self == .simple ? "EDIT_FRAME_COLOR_SIMPLE" : "EDIT_FRAME_COLOR_GRADIENT" }
}

// メニュー項目を列挙
enum EditMenuItem: String, CaseIterable, Identifiable {
    case layout // フレームレイアウト
    case filter // フィルター
    case date // 日付の表示・非表示
    case color // カラー
    
    var id: Self { self }
    
    /// SF Symbol 名
    var iconName: String {
        switch self {
        case .layout: return "square"
        case .filter: return "camera.filters"
        case .date: return "clock"
        case .color: return "paintpalette"
        }
    }
    
    /// 表示用タイトル
    var title: String {
        switch self {
        case .layout: return "EDIT_LAYOUT"
        case .filter: return "EDIT_FILTER"
        case .date: return "EDIT_DATE"
        case .color: return "EDIT_FRAME_COLOR"
        }
    }
}

// フィルターの種類
enum FilterType: String, CaseIterable, Identifiable {
    case none, mono, noir, instant, process, chrome, transfer, sepia
    case bloom, posterize, comic, pixellate, invert
    
    var id: Self { self }
    
    /// メニューに出す名前
    var displayName: String {
        switch self {
        case .none: return "None"
        case .noir: return "Noir"
        case .mono: return "Mono"
        case .chrome: return "Chrome"
        case .instant: return "Instant"
        case .transfer: return "Transfer"
        case .process: return "Process"
//        case .tonal: return "Tonal"
        case .sepia: return "Sepia"
//        case .fade:       return "Fade"
        case .invert: return "Invert"
        case .posterize: return "Posterize"
        case .bloom: return "Bloom"
        case .comic: return "Comic"
        case .pixellate: return "Pixellate"
        }
    }
    
    /// CIFilter 名
    var ciName: String? {
        switch self {
        case .none: return nil
        case .noir: return "CIPhotoEffectNoir" // モノクロ・ノワール
        case .mono: return "CIPhotoEffectMono" // 白黒
        case .chrome: return "CIPhotoEffectChrome" // コントラスト強調
        case .instant: return "CIPhotoEffectInstant" // インスタントカメラ風
        case .transfer: return "CIPhotoEffectTransfer" // ビンテージ風
        case .process: return "CIPhotoEffectProcess" // フィルム風
//        case .tonal: return "CIPhotoEffectTonal" // トーナル調整
        case .sepia: return "CISepiaTone" // セピア
//        case .fade: return "CIPhotoEffectFade" // 色を薄くフェードさせたビンテージ調。
        case .invert: return "CIColorInvert" // 色の反転
        case .posterize: return "CIColorPosterize" // ポスタリゼーション風で、イラスト的にポップに
        case .bloom: return "CIBloom" // 明るい部分をにじませるように光彩を強調
        case .comic: return "CIComicEffect" // コミック／マンガ調
        case .pixellate: return "CIPixellate" // ドット状に粗く
        }
    }
}

// CIColorInvert, CIColorMonochrome, CIColorPosterize… より細かい色調整用

extension DateFormatter {
    /// '25 7 14 の形式（アポストロフィ＋下2桁西暦＋空白区切り）で返す DateFormatter
    static let chekiStyle: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "'yy M d"
        return f
    }()
}
