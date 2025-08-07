
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos
import SwiftUI
import Vision

struct PhotoEditorView: View {
    // 入力
    private let asset: PHAsset? // PHAsset 経由で渡される場合
    private let capturedUIImage: UIImage? // カメラ撮影後に渡される場合
    
    // MARK: - State
    
    @State private var originalImage: UIImage? = nil
    @State private var silhouetteImage: UIImage? = nil
    @State private var isProcessing = false // 処理中フラグ
    
    // 共有／保存
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showSaveMenu = false
    @State private var showSavedToast = false
    
    // 全画面広告
    @StateObject private var adViewModel = InterstitialViewModel()
    
    // MARK: - Core Image
    
    private let ciContext = CIContext()
    private let thresholdFilter = CIFilter.colorClamp()
    private let blendFilter = CIFilter.blendWithMask()
    
    // MARK: — イニシャライザ
    
    /// PHAsset から開く場合
    init(asset: PHAsset) {
        self.asset = asset
        self.capturedUIImage = nil
    }
    
    /// カメラ撮影後の UIImage を開く場合
    init(capturedUIImage: UIImage) {
        self.asset = nil
        self.capturedUIImage = capturedUIImage
    }
    
    // MARK: — Body
    
    var body: some View {
        ZStack {
            // 背景色
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            // メインコンテンツ
            VStack(spacing: 0) {
                // 1.画像プレビューエリア
                previewSection
                    .frame(maxWidth: .infinity)
                
                // 2. コントロールパネル
                controlPanel
                    .padding(.horizontal, 16)

                // 3. 保存、共有ボタン
                actionButtons
                    .padding(.bottom, 5)
                    .padding(.horizontal, 16)
            }
            
            // 保存オーバーレイ
            overlayViews
        }
        .navigationBarSetting(title: "", isVisible: true)
        .navigationBarIconSetting(
            name: "square.and.arrow.down",
            isEnabled: true,
            iconPosition: .trailing,
            action: onTappedSaveIcon
        )
        // 確認ダイアログを定義
        .confirmationDialog("SHEET_ACTION_SELECT", isPresented: $showSaveMenu, titleVisibility: .visible) {
            Button("SHEET_SAVE") { saveImage() }
            Button("SHEET_SHARE") { shareImage() }
            Button("SHEET_CANCEL", role: .cancel) {}
        }
        .animation(.easeInOut, value: showSavedToast)
        .sheet(isPresented: $showingShareSheet, onDismiss: handleShareDismiss) {
            if !shareItems.isEmpty {
                ShareSheet(activityItems: shareItems)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            if let img = capturedUIImage {
                originalImage = img
                processSilhouette(from: img)
            } else if let asst = asset {
                loadImage(from: asst)
            }
            
            // 広告読み込み
            Task { await adViewModel.loadAd() }
        }
    }
    
    // MARK: - 保存処理
    
    private func onTappedSaveIcon() {
        showSaveMenu = true
    }
    
    private func handleSave() {
        // ① ローディングを表示
        isProcessing = true
    }
    
    // MARK: - UI：プレビューセクション
    
//    private var previewSection: some View {
//        Group {
//            if let sil = silhouetteImage {
//                ZStack {
//                    CheckerboardView()
//                    Image(uiImage: sil)
//                        .resizable()
//                        .aspectRatio(sil.size, contentMode: .fit)
//                        .frame(maxWidth: .infinity)
//                }
//            } else if let img = originalImage {
//                Image(uiImage: img)
//                    .resizable()
//                    .aspectRatio(img.size, contentMode: .fit)
//                    .frame(maxWidth: .infinity)
//                    .opacity(0.3)
//            } else {
//                ProgressView()
//            }
//        }
//        // 必要であれば .padding() を horizontal だけにするなど調整してください
//    }
    
//    private var previewSection: some View {
//        Group {
//            if let sil = silhouetteImage {
//                // アスペクト比を保持しつつ、チェックボードとシルエットを同じフレームで重ねる
//                GeometryReader { geo in
//                    let aspect = sil.size.width / sil.size.height
//                    let width = geo.size.width
//                    let height = width / aspect
//                    VStack(spacing: 0) {
//                        Spacer()
//                        ZStack {
//                            CheckerboardView()
//                            Image(uiImage: sil)
//                                .resizable()
//                                .scaledToFit()
//                        }
//                        .frame(width: width, height: height)
//
//                    }
//                }
//            } else if let img = originalImage {
//                Image(uiImage: img)
//                    .resizable()
//                    .scaledToFit()
//                    .opacity(0.3)
//            } else {
//                ProgressView()
//            }
//        }
//    }
    
    // MARK: — Preview Section

    private var previewSection: some View {
        GeometryReader { geo in
            let width = geo.size.width

            VStack(spacing: 0) {
                if let img = silhouetteImage ?? originalImage {
                    // 画像のアスペクト比を維持してサイズ計算
                    let aspect = img.size.width/img.size.height
                    let height = width/aspect
                 
                    ZStack {
                        // チェッカーボード背景
                        CheckerboardView()
                            .frame(width: width, height: height)
                        // 画像表示
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: width, height: height)
                            .opacity(silhouetteImage == nil ? 0.3 : 1.0)
                    }
                    .clipped()
                    // 上寄せで配置
                    .frame(width: width, height: height, alignment: .top)
                } else {
                    ProgressView()
                        .frame(width: width)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: — Control Panel Section：編集メニュー
    
    private var controlPanel: some View {
        // —— プレビュー下に「左右反転」「上下反転」「90度回転」ボタンを並べる
        HStack {
            // 左90°回転ボタン
            Button(action: rotateLeft) {
                VStack(spacing: 5) {
                    Image(systemName: "rotate.left")
                        .font(.title2)
                    Text("LEFT_ROTATION")
                        .font(.footnote)
                        .lineLimit(1) // 必ず一行に制限
                        .minimumScaleFactor(0.5) // 最大で半分のサイズまで縮小
                        .allowsTightening(true) // 文字間を詰めて表示
                        .layoutPriority(1) // 他のビューより優先してスペースを使う
                }
            }
            
            Spacer()
            
            Button(action: flipHorizontal) {
                VStack(spacing: 5) {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        .font(.title2)
                    Text("FLIP_HORIZONTAL")
                        .font(.footnote)
                        .lineLimit(1) // 必ず一行に制限
                        .minimumScaleFactor(0.5) // 最大で半分のサイズまで縮小
                        .allowsTightening(true) // 文字間を詰めて表示
                        .layoutPriority(1) // 他のビューより優先してスペースを使う
                }
            }
            
            Spacer()
            
            Button(action: flipVertical) {
                VStack(spacing: 5) {
                    Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                        .font(.title2)
                    Text("FLIP_VERTICAL")
                        .font(.footnote)
                        .lineLimit(1) // 必ず一行に制限
                        .minimumScaleFactor(0.5) // 最大で半分のサイズまで縮小
                        .allowsTightening(true) // 文字間を詰めて表示
                        .layoutPriority(1) // 他のビューより優先してスペースを使う
                }
            }
            
            Spacer()
            
            // 右90°回転ボタン
            Button(action: rotateRight) {
                VStack(spacing: 5) {
                    Image(systemName: "rotate.right")
                        .font(.title2)
                    Text("RIGHT_ROTATION")
                        .font(.footnote)
                        .lineLimit(1) // 必ず一行に制限
                        .minimumScaleFactor(0.5) // 最大で半分のサイズまで縮小
                        .allowsTightening(true) // 文字間を詰めて表示
                        .layoutPriority(1) // 他のビューより優先してスペースを使う
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
    
    // MARK: — 保存／共有ボタン
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: saveImage) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.white)
                    Text("BUTTON_SAVE")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button(action: shareImage) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                    Text("BUTTON_SHARE")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: — Transformation Actions

    private func rotateLeft() {
        guard let img = silhouetteImage else { return }
        silhouetteImage = transformed(image: img, rotation: -.pi/2)
    }

    private func rotateRight() {
        guard let img = silhouetteImage else { return }
        silhouetteImage = transformed(image: img, rotation: .pi/2)
    }

    private func flipHorizontal() {
        guard let img = silhouetteImage else { return }
        silhouetteImage = flipped(image: img, horizontal: true)
    }

    private func flipVertical() {
        guard let img = silhouetteImage else { return }
        silhouetteImage = flipped(image: img, horizontal: false)
    }
    
    private func transformed(image: UIImage, rotation: CGFloat) -> UIImage? {
        let size = CGSize(width: image.size.height, height: image.size.width)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: size.width/2, y: size.height/2)
            ctx.cgContext.rotate(by: rotation)
            image.draw(in: CGRect(x: -image.size.width/2,
                                  y: -image.size.height/2,
                                  width: image.size.width,
                                  height: image.size.height))
        }
    }

    private func flipped(image: UIImage, horizontal: Bool) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            if horizontal {
                ctx.cgContext.translateBy(x: image.size.width, y: 0)
                ctx.cgContext.scaleBy(x: -1, y: 1)
            } else {
                ctx.cgContext.translateBy(x: 0, y: image.size.height)
                ctx.cgContext.scaleBy(x: 1, y: -1)
            }
            image.draw(at: .zero)
        }
    }

    // MARK: — 共有処理
    
    // todo
    private func handleShare() {
        // ① ローディングを表示
        isProcessing = true
        
        // ② スナップショット取得はメインスレッドで必ず実行
        DispatchQueue.main.async {
            // ③ 一時ファイル書き込み→シェアシート呼び出しはメインスレッド or 遅延で OK
            let df = DateFormatter()
            df.dateFormat = "yyyy_MM_dd"
            let name = df.string(from: Date()) + "_" + UUID().uuidString + ".jpg"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shareItems = [url]
                showingShareSheet = true
                isProcessing = false
            }
        }
    }
    
    private func handleShareDismiss() {
        showingShareSheet = false
        shareItems = []
        DispatchQueue.main.async {
            if Int.random(in: 1 ... 2) == 1 {
                adViewModel.showAd()
            }
        }
    }
    
    // MARK: — トースト・処理中オーバーレイ
    
    @ViewBuilder
    private var overlayViews: some View {
        if showSavedToast {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            Text("NOTIFICATION_SAVED")
                .font(.body)
                .padding(24)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 8)
        }
        
        if isProcessing {
            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                ProgressView()
                Text("NOTIFICATION_PROCESSING").font(.body)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
    
    // MARK: — PHAsset から UIImage を読み込む
    
    private func loadImage(from asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            guard let img = image else { return }
            DispatchQueue.main.async {
                originalImage = img
                processSilhouette(from: img)
            }
        }
    }
    
    // MARK: — Silhouette Processing
    
    private func processSilhouette(from image: UIImage) {
        isProcessing = true
        generatePersonMask(from: image) { maskCI in
            guard let mask = maskCI,
                  let silhouette = createSilhouette(from: image, maskCI: mask)
            else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }
            DispatchQueue.main.async {
                silhouetteImage = silhouette
                isProcessing = false
            }
        }
    }
    
    private func generatePersonMask(from uiImage: UIImage, completion: @escaping (CIImage?) -> Void) {
        guard let cgImage = uiImage.cgImage else { completion(nil); return }
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                if let pixelBuffer = request.results?.first?.pixelBuffer {
                    completion(CIImage(cvPixelBuffer: pixelBuffer))
                } else {
                    completion(nil)
                }
            } catch {
                print("Segmentation error: \(error)")
                completion(nil)
            }
        }
    }
    
//    private func createSilhouette(from original: UIImage, maskCI: CIImage) -> UIImage? {
//        let ciImage = CIImage(image: original)!
//        // 黒/白塗りつぶし（マスクをそのまま使用）
//        let black = CIImage(color: .black).cropped(to: ciImage.extent)
//        let white = CIImage(color: .white).cropped(to: ciImage.extent)
//        blendFilter.inputImage = black
//        blendFilter.backgroundImage = white
//        blendFilter.maskImage = maskCI
//        guard let output = blendFilter.outputImage,
//              let cg = ciContext.createCGImage(output, from: ciImage.extent)
//        else { return nil }
//        return UIImage(cgImage: cg)
//    }
    
//    private func createSilhouette(from original: UIImage, maskCI: CIImage) -> UIImage? {
//        let ciImage = CIImage(image: original)!
//        // マスクを元画像サイズにスケーリング
//        let maskExtent = maskCI.extent
//        let scaleX = ciImage.extent.width / maskExtent.width
//        let scaleY = ciImage.extent.height / maskExtent.height
//        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
//
//        // 二値化
//        thresholdFilter.inputImage = scaledMask
//        thresholdFilter.minComponents = CIVector(x: 0.5, y: 0.5, z: 0.5, w: 0.5)
//        thresholdFilter.maxComponents = CIVector(x: 1,   y: 1,   z: 1,   w: 1)
//        guard let binaryMask = thresholdFilter.outputImage else { return nil }
//        // 黒/白塗りつぶし
//        let black = CIImage(color: .black).cropped(to: ciImage.extent)
//        let white = CIImage(color: .white).cropped(to: ciImage.extent)
//        blendFilter.inputImage = black
//        blendFilter.backgroundImage = white
//        blendFilter.maskImage = binaryMask
//        guard let output = blendFilter.outputImage,
//              let cg = ciContext.createCGImage(output, from: ciImage.extent)
//        else { return nil }
//        return UIImage(cgImage: cg)
//    }
    
    private func createSilhouette(from original: UIImage, maskCI: CIImage) -> UIImage? {
        // 元画像と同じ解像度・向きでCIImage作成
        let ciImage = CIImage(image: original)!
        // マスクを元画像サイズにスケーリング
        let maskExtent = maskCI.extent
        let scaleX = ciImage.extent.width/maskExtent.width
        let scaleY = ciImage.extent.height/maskExtent.height
        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // 黒いシルエット生成、背景は透明
        let blackImage = CIImage(color: .black).cropped(to: ciImage.extent)
        let transparentImage = CIImage(color: .clear).cropped(to: ciImage.extent)
        blendFilter.inputImage = blackImage
        blendFilter.backgroundImage = transparentImage
        blendFilter.maskImage = scaledMask
        
        // 合成してUIImage化
        guard let outputCI = blendFilter.outputImage,
              let cgImg = ciContext.createCGImage(outputCI, from: ciImage.extent)
        else { return nil }
        return UIImage(cgImage: cgImg, scale: original.scale, orientation: original.imageOrientation)
    }

    // MARK: — Save / Share
    
    private func saveImage() {
        guard let sil = silhouetteImage else { return }
        isProcessing = true
        UIImageWriteToSavedPhotosAlbum(sil, nil, nil, nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
            showSavedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSavedToast = false
                if Int.random(in: 1 ... 2) == 1 { adViewModel.showAd() }
            }
        }
    }
    
    private func shareImage() {
        guard let sil = silhouetteImage else { return }
        isProcessing = true
        let name = "silhouette_" + UUID().uuidString + ".png"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        if let data = sil.pngData() {
            try? data.write(to: url)
            shareItems = [url]
            showingShareSheet = true
        }
        isProcessing = false
    }
}
