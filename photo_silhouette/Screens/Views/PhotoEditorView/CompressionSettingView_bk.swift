////
////  CompressionSettingView.swift
////  photo-compressor
////
////  Created by 尾野順哉 on 2025/04/15.
////
//
////
////  CompressionSettingView.swift
////  photo-compressor
////
////  Created by 尾野順哉 on 2025/04/15.
////
//
//import AVFoundation
//import Photos
//import SwiftUI
//
//struct CompressionSettingView: View {
//    let asset: PHAsset
//
//    // 画像サイズ指定方法：固定サイズ / パーセンテージ
//    @State private var selectedSizeType: SizeType = .fixed
//    @State private var fixedSizeSelection: FixedSizeOption = .size640
//    @State private var scalePercentage: Double = 50.0
//    
//    // 画質選択 (最低～最高) - PNG選択時は非表示にする
//    @State private var selectedQuality: ImageQuality = .standard
//    
//    // Exif情報を保持するか
//    @State private var keepExif: Bool = true
//    
//    // 変換後のファイル形式 (segmented)
//    @State private var selectedFormat: ImageFormat = .jpeg
//    
//    // デフォルトを after に (圧縮結果を表示)
//    @State private var displayMode: DisplayMode = .after
//    
//    // 読み込み画像
//    @State private var originalImage: UIImage? = nil
//    @State private var compressedImage: UIImage? = nil
//    
//    // ファイル情報
//    @State private var beforeFileSize: String = ""
//    @State private var beforeDimensions: String = ""
//    @State private var afterFileSize: String = ""
//    @State private var afterDimensions: String = ""
//    
//    // 保存処理中・保存完了メッセージ用のフラグ
//    @State private var isSaving: Bool = false
//    @State private var saveStatusMessage: String? = nil
//    
//    // ピンチズームのための状態変数
//    @State private var currentScale: CGFloat = 1.0
//    @State private var lastScaleValue: CGFloat = 1.0
//    
//    // ★ 新規：圧縮前のオリジナル画像を削除する（＝最近削除へ移動する）かどうかのトグル
//    @State private var deleteOriginalAfterSave: Bool = false
//    
//    // 全画面広告
//    @StateObject private var adViewModel = InterstitialViewModel()
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                previewSection
//                
//                sizeSelectionSection
//                
//                formatSelectionSection
//                
//                // PNGの場合は画質Pickerを非表示
//                if selectedFormat != .png {
//                    qualitySelectionSection
//                }
//                
//                Toggle("KEEP_EXIF_METADATA", isOn: $keepExif)
//                    .padding(.bottom, 12)
//                
//                // ★ 新規：圧縮前のオリジナル画像を削除する（＝最近削除へ移動）トグル
//                Toggle("DELETE_ORIGINAL_AFTER_SAVE", isOn: $deleteOriginalAfterSave)
//                    .padding(.bottom, 16)
//                
//                buttonSection
//                
//                Spacer(minLength: 20)
//            }
//            .padding()
//        }
//        // ナビゲーションバーのタイトル
//        .navigationBarSetting(title: "IMAGE_COMPRESSION_SETTINGS", isVisible: true)
//        .onAppear {
//            // 画像の読み込み
//            loadOriginalImage()
//            
//            // 広告の読み込み
//            Task {
//                await adViewModel.loadAd()
//            }
//        }
//        // 設定変更時は自動で圧縮プレビューを更新
//        .onChange(of: originalImage) { _ in compressAndPreview() }
//        .onChange(of: selectedSizeType) { _ in compressAndPreview() }
//        .onChange(of: fixedSizeSelection) { _ in
//            if selectedSizeType == .fixed { compressAndPreview() }
//        }
//        .onChange(of: scalePercentage) { _ in
//            if selectedSizeType == .percentage { compressAndPreview() }
//        }
//        .onChange(of: selectedFormat) { _ in compressAndPreview() }
//        .onChange(of: selectedQuality) { _ in compressAndPreview() }
//        .onChange(of: keepExif) { _ in compressAndPreview() }
//        .overlay(
//            Group {
//                // 保存処理中や保存完了メッセージ表示
//                if isSaving {
//                    ProgressView("SAVING")
//                        .padding(30)
//                        .background(Color("FlashMessageBackgroundColor"))
//                        .cornerRadius(10)
//                        .shadow(radius: 10)
//                } else if let message = saveStatusMessage {
//                    Text(LocalizedStringKey(message))
//                        .foregroundColor(Color("FlashMessageTextColor"))
//                        .padding(30)
//                        .background(Color("FlashMessageBackgroundColor"))
//                        .cornerRadius(10)
//                        .shadow(radius: 10)
//                        .transition(.opacity)
//                }
//            },
//            alignment: .center
//        )
//    }
//}
//
//// MARK: - プレビューセクション
//
//extension CompressionSettingView {
//    private var previewSection: some View {
//        VStack(spacing: 8) {
//            // Before / After 切替用Picker
//            Picker("表示", selection: $displayMode) {
//                Text("Before").tag(DisplayMode.before)
//                Text("After").tag(DisplayMode.after)
//            }
//            .pickerStyle(.segmented)
//            
//            // プレビュー画像エリアを ZStack でラップし、上部にファイル情報のオーバーレイを配置
//            ZStack(alignment: .topLeading) {
//                Group {
//                    if displayMode == .before {
//                        if let original = originalImage {
//                            Image(uiImage: original)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .scaleEffect(currentScale)
//                        } else {
//                            Color.gray
//                        }
//                    } else {
//                        if let compressed = compressedImage {
//                            Image(uiImage: compressed)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .scaleEffect(currentScale)
//                        } else {
//                            Color.gray
//                        }
//                    }
//                }
//                // エリアサイズの固定およびクリッピング
//                .frame(maxWidth: .infinity)
//                .frame(height: 400)
//                .clipped()
//            
//                // ファイル情報のオーバーレイ（例：左上に表示）
//                HStack {
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text(beforeDimensions)
//                            .font(.caption)
//                            .foregroundColor(.white)
//                        Text(beforeFileSize)
//                            .font(.caption)
//                            .foregroundColor(.white)
//                    }
//                    .padding(8)
//                    .background(Color.black.opacity(0.6))
//                    .cornerRadius(4)
//                    
//                    Spacer()
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text(afterDimensions)
//                            .font(.caption)
//                            .foregroundColor(.white)
//                        Text(afterFileSize)
//                            .font(.caption)
//                            .foregroundColor(.white)
//                    }
//                    .padding(8)
//                    .background(Color.black.opacity(0.6))
//                    .cornerRadius(4)
//                }
//                .padding(8)
//            }
//            // タッチ領域をプレビューエリア全体に拡張
//            .contentShape(Rectangle())
//            // ピンチジェスチャーはエリア全体に対して有効
//            .gesture(pinchGesture)
//            .simultaneousGesture(doubleTapGesture)
//            .border(Color.gray.opacity(0.3), width: 2)
//        }
//    }
//    
//    // MARK: - ピンチズーム用ジェスチャー
//
//    private var pinchGesture: some Gesture {
//        MagnificationGesture()
//            .onChanged { value in
//                // 現在の拡大率を更新
//                let delta = value / lastScaleValue
//                lastScaleValue = value
//                currentScale *= delta
//            }
//            .onEnded { _ in
//                // ジェスチャー終了後に lastScaleValue をリセット
//                lastScaleValue = 1.0
//            }
//    }
//    
//    // MARK: - ダブルタップジェスチャー
//
//    private var doubleTapGesture: some Gesture {
//        TapGesture(count: 2)
//            .onEnded {
//                // ダブルタップ時、現在の拡大率が1.0に近ければ2.0に、そうでなければリセットする
//                withAnimation {
//                    if abs(currentScale - 1.0) < 0.1 {
//                        currentScale = 2.0
//                    } else {
//                        currentScale = 1.0
//                    }
//                }
//            }
//    }
//}
//
//// MARK: - 画像サイズ指定セクション
//
//extension CompressionSettingView {
//    private var sizeSelectionSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("IMAGE_SIZE")
//                .font(.headline)
//            
//            // 固定 or パーセンテージ
//            Picker("サイズタイプ", selection: $selectedSizeType) {
//                Text("FIXED_SIZE").tag(SizeType.fixed)
//                Text("PERCENTAGE").tag(SizeType.percentage)
//            }
//            .pickerStyle(.segmented)
//            
//            if selectedSizeType == .fixed {
//                // 固定サイズ選択
//                Picker("固定サイズ", selection: $fixedSizeSelection) {
//                    ForEach(FixedSizeOption.allCases, id: \.self) { option in
//                        Text(option.title).tag(option)
//                    }
//                }
//                .pickerStyle(.segmented)
//            } else {
//                // パーセンテージ選択
//                HStack {
//                    Text("\(Int(scalePercentage))%")
//                        .frame(width: 50, alignment: .leading)
//                    Slider(value: $scalePercentage, in: 1 ... 100, step: 1)
//                }
//            }
//        }
//        .padding(.top, 8)
//        .padding(.bottom, 16)
//    }
//}
//
//// MARK: - ファイル形式セクション
//
//extension CompressionSettingView {
//    private var formatSelectionSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("FILE_FORMAT")
//                .font(.headline)
//            Picker("形式", selection: $selectedFormat) {
//                ForEach(ImageFormat.allCases, id: \.self) { format in
//                    Text(format.rawValue).tag(format)
//                }
//            }
//            .pickerStyle(.segmented)
//        }
//        .padding(.bottom, 16)
//    }
//}
//
//// MARK: - 画質選択セクション
//
//extension CompressionSettingView {
//    private var qualitySelectionSection: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("IMAGE_QUALITY")
//                .font(.headline)
//            Picker("画質", selection: $selectedQuality) {
//                ForEach(ImageQuality.allCases, id: \.self) { quality in
////                    Text(quality.rawValue).tag(quality)
//                    Text(LocalizedStringKey(quality.rawValue)).tag(quality)
//                }
//            }
//            .pickerStyle(.segmented)
//        }
//        .padding(.bottom, 16)
//    }
//}
//
//// MARK: - 保存／共有ボタンセクション
//
//extension CompressionSettingView {
//    private var buttonSection: some View {
//        VStack(spacing: 16) {
//            // 保存・共有ボタン
//            HStack(spacing: 20) {
//                // WebP 以外は「保存」ボタンを表示
//                if selectedFormat != .webp {
//                    Button(action: {
//                        compressAndSave()
//                    }) {
//                        HStack {
//                            Image(systemName: "square.and.arrow.down")
//                            Text("SAVE")
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .tint(.blue)
//                }
//         
//                Button(action: {
//                    compressAndShare()
//                }) {
//                    HStack {
//                        Image(systemName: "square.and.arrow.up")
//                        Text("SHARE")
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                }
//                .buttonStyle(.borderedProminent)
//                .tint(.blue)
//            }
//            // 注意書きも WebP のときは不要なら隠す
//            if selectedFormat != .webp {
//                Text("COMPRESSED_IMAGE_SAVED_TO_RECENTS")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//        }
//        .frame(maxWidth: .infinity)
//    }
//}
//
//// MARK: - メインロジック
//
//extension CompressionSettingView {
////    private func loadOriginalImage() {
////        let manager = PHCachingImageManager()
////        let targetSize = CGSize(width: 2000, height: 2000)
////        let options = PHImageRequestOptions()
////        options.isSynchronous = false
////        options.deliveryMode = .highQualityFormat
////        options.isNetworkAccessAllowed = true
////
////        manager.requestImage(for: asset,
////                             targetSize: targetSize,
////                             contentMode: .aspectFit,
////                             options: options) { result, _ in
////            if let result {
////                DispatchQueue.main.async {
////                    self.originalImage = result
////                    self.beforeFileSize = ByteCountFormatter.string(
////                        fromByteCount: Int64(result.jpegData(compressionQuality: 1.0)?.count ?? 0),
////                        countStyle: .file
////                    )
////                    self.beforeDimensions = "\(Int(result.size.width)) x \(Int(result.size.height))"
////                }
////            }
////        }
////    }
//    
//    // CompressionSettingView.swift 内
////    private func loadOriginalImage() {
////        let manager = PHImageManager.default()
////        let options = PHImageRequestOptions()
////        options.isNetworkAccessAllowed = true
////        options.deliveryMode = .highQualityFormat    // 高画質のみ
////        options.resizeMode = .none                   // リサイズなし
////
////        manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
////            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
////            // “低解像度プレビュー” は無視して、高品質データのみを採用
////            if !isDegraded, let data = data {
////                DispatchQueue.main.async {
////                    // サイズ表示
////                    self.beforeFileSize = ByteCountFormatter
////                        .string(fromByteCount: Int64(data.count), countStyle: .file)
////                    // 画像表示用にも同じデータを使いたければ
////                    if let img = UIImage(data: data) {
////                        self.originalImage = img
////                        self.beforeDimensions = "\(Int(img.size.width)) x \(Int(img.size.height))"
////                    }
////                    // 初回プレビュー更新
////                    compressAndPreview()
////                }
////            }
////        }
////    }
//    private func loadOriginalImage() {
//        // asset からリソース一覧を取って
//        let resources = PHAssetResource.assetResources(for: asset)
//        // Photo タイプのリソース（JPEG本体）を探す
//        if let photoResource = resources.first(where: { $0.type == .photo }) {
//            let data = NSMutableData()
//            let reqOptions = PHAssetResourceRequestOptions()
//            reqOptions.isNetworkAccessAllowed = true // iCloud からも取得可
//            
//            // チャンク単位でフルデータを受け取り
//            PHAssetResourceManager.default().requestData(
//                for: photoResource,
//                options: reqOptions,
//                dataReceivedHandler: { chunk in
//                    data.append(chunk)
//                },
//                completionHandler: { error in
//                    DispatchQueue.main.async {
//                        guard error == nil else {
//                            // エラー処理
//                            print("フルサイズ取得失敗: \(error!)")
//                            return
//                        }
//                        // サイズ表示
//                        let size = data.length
//                        self.beforeFileSize = ByteCountFormatter
//                            .string(fromByteCount: Int64(size), countStyle: .file)
//                        // プレビューにも使いたければ UIImage に変換
//                        if let img = UIImage(data: data as Data) {
//                            self.originalImage = img
//                            self.beforeDimensions = "\(Int(img.size.width)) x \(Int(img.size.height))"
//                        }
//                        // After プレビュー更新
//                        compressAndPreview()
//                    }
//                }
//            )
//        }
//    }
//    
//    private func compressAndPreview() {
//        guard let original = originalImage else { return }
//        let resized = resizedImage(original: original)
//        guard let compressedData = convertImageToData(
//            image: resized,
//            format: selectedFormat,
//            quality: selectedFormat == .png ? 1.0 : selectedQuality.qualityValue
//        ) else { return }
//        
//        if let newImage = UIImage(data: compressedData) {
//            DispatchQueue.main.async {
//                self.compressedImage = newImage
//                self.afterFileSize = ByteCountFormatter.string(
//                    fromByteCount: Int64(compressedData.count),
//                    countStyle: .file
//                )
//                self.afterDimensions = "\(Int(newImage.size.width)) x \(Int(newImage.size.height))"
//            }
//        }
//    }
//    
//    // 画像の圧縮と保存
//    private func compressAndSave() {
//        isSaving = true
//        DispatchQueue.global(qos: .userInitiated).async {
//            // プレビュー更新
//            self.compressAndPreview()
//
//            if let compressed = self.compressedImage {
//                UIImageWriteToSavedPhotosAlbum(compressed, nil, nil, nil)
//            }
//            // ★ 保存後、もし deleteOriginalAfterSave が true ならオリジナル画像（asset）を削除（＝最近削除へ移動）する
//            if self.deleteOriginalAfterSave {
//                PHPhotoLibrary.shared().performChanges({
//                    PHAssetChangeRequest.deleteAssets([self.asset] as NSArray)
//                }, completionHandler: { success, error in
//                    if !success {
//                        print("オリジナル削除に失敗: \(String(describing: error))")
//                    }
//                })
//            }
//  
//            // 広告表示と保存メッセージ
//            DispatchQueue.main.async {
//                self.isSaving = false
//                self.saveStatusMessage = nil
//                
//                // ランダムで表示判定（3分の1の確率で広告を出す）
//                let shouldShowAd = Int.random(in: 1 ... 3) == 1
//                
//                if shouldShowAd {
//                    // 広告が閉じた後にメッセージを出す
//                    self.adViewModel.onAdDismissed = {
//                        self.showSaveMessage()
//                    }
//                    self.adViewModel.showAd()
//                } else {
//                    // 広告を出さないので即メッセージ表示
//                    self.showSaveMessage()
//                }
//            }
//        }
//    }
//    
//    private func showSaveMessage() {
//        saveStatusMessage = "SAVED_SUCCESSFULLY"
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            withAnimation {
//                self.saveStatusMessage = nil
//            }
//        }
//    }
//   
//    private func compressAndShare() {
//        compressAndPreview()
//        guard let compressed = compressedImage,
//              let data = convertImageToData(
//                  image: compressed,
//                  format: selectedFormat,
//                  quality: selectedFormat == .png ? 1.0 : selectedQuality.qualityValue
//              )
//        else { return }
//        
//        // 一時ファイルとして保存
//        let fileExtension = selectedFormat.fileExtension
//        let tempURL = FileManager.default
//            .temporaryDirectory
//            .appendingPathComponent("Compressed_\(UUID().uuidString)\(fileExtension)")
//        do {
//            try data.write(to: tempURL)
//        } catch {
//            print("Error writing file: \(error)")
//            return
//        }
//        
//        let fileSizeString = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
//        // ShareFile クラスを用いて、ファイルURL・ファイル名・ファイルサイズ・UTI を付与
//        let shareItem = ShareFile(
//            fileURL: tempURL,
//            fileName: "Compressed\(fileExtension)",
//            fileSize: fileSizeString,
//            utiType: selectedFormat.utiType
//        )
//        
//        let activityVC = UIActivityViewController(activityItems: [shareItem], applicationActivities: nil)
//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let rootVC = scene.windows.first?.rootViewController {
//            rootVC.present(activityVC, animated: true, completion: nil)
//        }
//    }
//    
//    private func resizedImage(original: UIImage) -> UIImage {
//        let originalSize = original.size
//        let newSize: CGSize
//        
//        if selectedSizeType == .fixed {
//            let targetWidth = CGFloat(fixedSizeSelection.rawValue)
//            let ratio = targetWidth / originalSize.width
//            newSize = CGSize(width: targetWidth, height: originalSize.height * ratio)
//        } else {
//            let ratio = CGFloat(scalePercentage) / 100.0
//            newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
//        }
//        
//        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
//        original.draw(in: CGRect(origin: .zero, size: newSize))
//        let resized = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return resized ?? original
//    }
//    
//    private func convertImageToData(image: UIImage, format: ImageFormat, quality: CGFloat) -> Data? {
//        switch format {
//        case .jpeg:
//            return image.jpegData(compressionQuality: quality)
//        case .heic:
//            if #available(iOS 11.0, *) {
//                return image.heicData(compressionQuality: quality)
//            } else {
//                return image.jpegData(compressionQuality: quality)
//            }
//        case .png:
//            return image.pngData()
//        case .webp:
//            // WebP は外部ライブラリが必要なため、ここでは JPEG を代替として返す
//            return image.jpegData(compressionQuality: quality)
//        }
//    }
//}
//
//// MARK: - 列挙型
//
//extension CompressionSettingView {
//    enum SizeType {
//        case fixed, percentage
//    }
//    
//    enum FixedSizeOption: Int, CaseIterable {
//        case size320 = 320
//        case size640 = 640
//        case size960 = 960
//        case size1024 = 1024
//        case size1280 = 1280
//        case size2048 = 2048
//        
//        var title: String {
//            "\(rawValue)"
//        }
//    }
//    
//    enum ImageFormat: String, CaseIterable {
//        case jpeg = "JPEG"
//        case heic = "HEIC"
//        case png = "PNG"
//        case webp = "WebP"
//    }
//    
//    enum ImageQuality: String, CaseIterable, Hashable {
//        case lowest = "QUALITY_LOWEST"
//        case low = "QUALITY_LOW"
//        case standard = "QUALITY_STANDARD"
//        case high = "QUALITY_HIGH"
//        case highest = "QUALITY_HIGHEST"
//        
//        var qualityValue: CGFloat {
//            switch self {
//            case .lowest: return 0.2
//            case .low: return 0.4
//            case .standard: return 0.6
//            case .high: return 0.8
//            case .highest: return 1.0
//            }
//        }
//    }
//    
//    enum DisplayMode {
//        case before, after
//    }
//}
//
//// MARK: - UIImage+HEIC拡張
//
//extension UIImage {
//    func heicData(compressionQuality: CGFloat) -> Data? {
//        guard #available(iOS 11.0, *) else { return nil }
//        guard let cgImage else { return nil }
//        let mutableData = NSMutableData()
//        guard let destination = CGImageDestinationCreateWithData(mutableData, AVFileType.heic as CFString, 1, nil) else {
//            return nil
//        }
//        let options: [CFString: Any] = [
//            kCGImageDestinationLossyCompressionQuality: compressionQuality
//        ]
//        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
//        CGImageDestinationFinalize(destination)
//        return mutableData as Data
//    }
//}
//
//// MARK: - ImageFormat 拡張 (ファイル拡張子・UTI)
//
//extension CompressionSettingView.ImageFormat {
//    var fileExtension: String {
//        switch self {
//        case .jpeg: return ".jpg"
//        case .heic: return ".heic"
//        case .png: return ".png"
//        case .webp: return ".webp"
//        }
//    }
//    
//    var utiType: String {
//        switch self {
//        case .jpeg: return "public.jpeg"
//        case .heic: return "public.heic"
//        case .png: return "public.png"
//        case .webp: return "public.jpeg" // WebP用の標準UTIは存在しないため
//        }
//    }
//}
//
//// MARK: - カスタム共有用クラス
//
///// UIActivityItemSource を実装し、一時ファイル URL とファイル名・サイズを付与する
//final class ShareFile: NSObject, UIActivityItemSource {
//    let fileURL: URL
//    let fileName: String
//    let fileSize: String
//    let utiType: String
//    
//    init(fileURL: URL, fileName: String, fileSize: String, utiType: String) {
//        self.fileURL = fileURL
//        self.fileName = fileName
//        self.fileSize = fileSize
//        self.utiType = utiType
//        super.init()
//    }
//    
//    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
//        return fileURL
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController,
//                                itemForActivityType activityType: UIActivity.ActivityType?) -> Any {
//        return fileURL
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController,
//                                subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
//        return fileName
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController,
//                                dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
//        return utiType
//    }
//    
//    func activityViewController(_ activityViewController: UIActivityViewController,
//                                thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
//                                suggestedSize size: CGSize) -> UIImage? {
//        // カスタムサムネイルの合成（受け手アプリによっては無視される可能性あり）
//        guard let baseImage = UIImage(contentsOfFile: fileURL.path) else { return nil }
//        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
//        let previewImage = renderer.image { _ in
//            baseImage.draw(in: CGRect(origin: .zero, size: baseImage.size))
//            let overlayText = "\(fileName)\n\(fileSize)"
//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.alignment = .left
//            let attributes: [NSAttributedString.Key: Any] = [
//                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
//                .foregroundColor: UIColor.white,
//                .paragraphStyle: paragraphStyle,
//                .backgroundColor: UIColor.black.withAlphaComponent(0.5)
//            ]
//            let textRect = CGRect(x: 10, y: 10, width: baseImage.size.width - 20, height: baseImage.size.height - 20)
//            overlayText.draw(in: textRect, withAttributes: attributes)
//        }
//        return previewImage
//    }
//}
