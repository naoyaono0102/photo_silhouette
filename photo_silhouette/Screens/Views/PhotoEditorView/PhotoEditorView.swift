
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos
import SwiftUI
import UIKit
import Vision

struct PhotoEditorView: View {
    // 入力
    private let asset: PHAsset? // PHAsset 経由で渡される場合
    private let capturedUIImage: UIImage? // カメラ撮影後に渡される場合

    // MARK: - State

    @State private var originalImage: UIImage? = nil
    @State private var silhouetteImage: UIImage? = nil
    @State private var baseSilhouetteImage: UIImage? = nil
    @State private var isProcessing = false // 処理中フラグ

    @State private var previewContainerPt: CGSize = .zero // 追加：プレビュー領域そのものの実寸(pt)
    @State private var previewFramePt: CGSize = .zero // 既存：フレーム実寸(pt)

    // 共有／保存
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showSaveMenu = false
    @State private var showSavedToast = false

    // 追加: 回転・反転状態
    @State private var rotationAngle: Angle = .zero
    @State private var scaleX: CGFloat = 1
    @State private var scaleY: CGFloat = 1

    // 全画面広告
    @StateObject private var adViewModel = InterstitialViewModel()

    /// 単位は“px”
    // 既存の targetWidthPx, targetHeightPx は「プレビューに反映される値」として使う
    @State private var targetWidthPx: Double = 300
    @State private var targetHeightPx: Double = 300

    // 新規：テキストフィールドにバインドする“編集中の値”
    @State private var editingWidthPx: Double = 300
    @State private var editingHeightPx: Double = 300

    ///  縦横比固定モードを切り替え
    @State private var lockAspect: Bool = false

    @State private var didInitialize = false

    // どの TextField がフォーカス中かを管理
    private enum Field { case width, height }
    @FocusState private var focusedField: Field?

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

    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero

    // MARK: — Body

    var body: some View {
        ZStack {
            // 背景色
            Color("BackgroundColor")
                .ignoresSafeArea()

            // メインコンテンツ
            VStack(spacing: 0) {
                // 0. サイズパネル
                sizePanel

                // 1.画像プレビューエリア
                previewSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.gray)

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
        // 画面外タップでキーボードを閉じる
        .contentShape(Rectangle()) // ZStack 全体をタップ対象に
        .onTapGesture {
            UIApplication.shared.endEditing()
        }
        // キーボード上部にツールバーを追加
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    focusedField = nil
                }
            }
        }
        // キーボードを閉じたら縦横サイズを反映
        .onChange(of: focusedField) { new in
            // フォーカスがなくなった（＝完了ボタン or 画面外タップ）とき
            if new == nil {
                targetWidthPx = editingWidthPx
                targetHeightPx = editingHeightPx
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // コンテンツの上にキーボードをかぶせる
        .navigationBarSetting(title: "", isVisible: true)
        .navigationBarIconSetting(name: "arrow.clockwise",
                                  isEnabled: true,
                                  iconPosition: .trailing,
                                  action: reset)
        .animation(.easeInOut, value: showSavedToast)
        .sheet(isPresented: $showingShareSheet, onDismiss: handleShareDismiss) {
            if !shareItems.isEmpty {
                ShareSheet(activityItems: shareItems)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            // 初期化完了済の場合はスキップ
            guard !didInitialize else { return }

            editingWidthPx = targetWidthPx
            editingHeightPx = targetHeightPx

            if let img = capturedUIImage {
                originalImage = img
                initSizeFromImage(img)
                processSilhouette(from: img)
            } else if let asst = asset {
                loadImage(from: asst)
            }

            // 広告読み込み
            Task { await adViewModel.loadAd() }
            didInitialize = true
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

    // MARK: - 画像の初期サイズをセット

    /// UIImage の pixel サイズを State にセットする
    private func initSizeFromImage(_ img: UIImage) {
        if let cg = img.cgImage {
            targetWidthPx = Double(cg.width)
            targetHeightPx = Double(cg.height)
            editingWidthPx = targetWidthPx
            editingHeightPx = targetHeightPx
        }
    }

    // MARK: - サイズ調整

    private var sizePanel: some View {
        HStack(spacing: 16) {
            VStack {
                Text("幅 (px)")
                TextField("", value: $editingWidthPx, format: .number)
                    .focused($focusedField, equals: .width)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
            VStack {
                Text("高さ (px)")
                TextField("", value: $editingHeightPx, format: .number)
                    .focused($focusedField, equals: .height)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: — Preview Section

    private var previewSection: some View {
        GeometryReader { geo in
            // 1) ユーザー指定 px → pt
            let scale = UIScreen.main.scale
            let desiredW = CGFloat(targetWidthPx)/scale
            let desiredH = CGFloat(targetHeightPx)/scale

            // 2) プレビューの表示領域（pt）
            let maxW = geo.size.width
            let maxH = geo.size.height

            // 3) フレーム比を保ったまま、画面にはみ出ない最大サイズを算出
            let frameRatio = desiredW/desiredH
            let screenRatio = maxW/maxH

            let displayW: CGFloat = frameRatio > screenRatio
                ? min(desiredW, maxW) // 横を合わせる
                : min(desiredH * frameRatio, maxW) // 縦基準で横を決める

            let displayH: CGFloat = frameRatio > screenRatio
                ? displayW/frameRatio // 横に合わせたので高さは比率から
                : min(desiredH, maxH) // 縦を合わせる

            ZStack {
                Color.gray // previewSection 全体の背景

                VStack {
                    Spacer()
                    // ← この ZStack が「ユーザーが指定したフレーム」(displayW x displayH)
                    ZStack {
                        CheckerboardView()
                        if let img = silhouetteImage ?? originalImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit) // フレーム内で元比を維持
                                .scaleEffect(zoomScale) // 画像に拡大縮小
                                .offset(dragOffset) // 画像にパン
                        }
                    }
                    .frame(width: displayW, height: displayH) // ★ フレームの実サイズをここで固定
                    .clipped() // ★ 枠からはみ出した部分は描かない
                    .contentShape(Rectangle()) // 透明部分もタップ可
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                dragOffset = CGSize(
                                    width: lastDragOffset.width + v.translation.width,
                                    height: lastDragOffset.height + v.translation.height
                                )
                            }
                            .onEnded { _ in lastDragOffset = dragOffset }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { v in zoomScale = lastZoomScale * v }
                            .onEnded { _ in lastZoomScale = zoomScale }
                    )
                    // フレーム実寸（pt）を保存（エクスポート時の pt→px 換算で使用）
                    .onAppear { previewFramePt = CGSize(width: displayW, height: displayH) }
                    .onChange(of: displayW) { _ in previewFramePt = CGSize(width: displayW, height: displayH) }
                    .onChange(of: displayH) { _ in previewFramePt = CGSize(width: displayW, height: displayH) }

                    Spacer()
                }
                .frame(width: maxW, height: maxH)
            }
            // ★ ここ（外側）で「プレビューコンテナ実寸」を安定して取得
            .background(
                GeometryReader { p in
                    Color.clear
                        .onAppear {
                            previewContainerPt = p.size
                            previewFramePt = recalcFramePt(container: p.size)
                        }
                        .onChange(of: p.size) { newSize in
                            previewContainerPt = newSize
                            previewFramePt = recalcFramePt(container: newSize)
                        }
                }
            )
            // 入力が変わったらフレーム実寸を再計算
            .onChange(of: targetWidthPx) { _ in
                previewFramePt = recalcFramePt(container: previewContainerPt)
            }
            .onChange(of: targetHeightPx) { _ in
                previewFramePt = recalcFramePt(container: previewContainerPt)
            }
        }
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
        .padding(.bottom, 6)
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

    // MARK: - Transform Actions

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

    private func reset() {
        // ① 画像自体は元のシルエットに戻す
        if let base = baseSilhouetteImage {
            silhouetteImage = base
        }
        // ② ズーム・オフセット状態をリセット
        zoomScale = 1.0
        lastZoomScale = 1.0
        dragOffset = .zero
        lastDragOffset = .zero
        // （必要なら回転・反転もリセット）
        rotationAngle = .zero
        scaleX = 1; scaleY = 1
    }

    // MARK: - Image Transforms

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
                initSizeFromImage(img)
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
                baseSilhouetteImage = silhouette
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

    // 1) 保存フロー本体（ボタンからこれを呼ぶ）
    private func saveImage() {
        // ① ローディング表示
        isProcessing = true

        // ② 画像生成は必ずメインスレッド
        DispatchQueue.main.async {
            guard let img = exportImage() else {
                isProcessing = false
                return
            }

            // ③ バックグラウンドでカメラロール保存（完了はハンドラで受ける）
            DispatchQueue.global(qos: .userInitiated).async {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }) { success, error in
                    DispatchQueue.main.async {
                        isProcessing = false

                        // 失敗時は即終了（必要ならエラー表示）
                        guard error == nil, success else {
                            // TODO: エラーToastなど
                            return
                        }

                        // ④ 広告 or トースト
                        let showAdNow = Int.random(in: 1 ... 3) == 1

                        let showToast: () -> Void = {
                            withAnimation { showSavedToast = true }
                            // 2秒後に自動で閉じる
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSavedToast = false }
                            }
                        }

                        if showAdNow {
                            // Interstitial の dismiss コールバックがある前提
                            adViewModel.onAdDismissed = { showToast() }
                            adViewModel.showAd()
                        } else {
                            showToast()
                        }
                    }
                }
            }
        }
    }

    private func shareImage() {
        isProcessing = true
        guard let img = exportImage(),
              let data = img.pngData()
        else {
            isProcessing = false
            return
        }
        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("silhouette_\(UUID()).png")
        try? data.write(to: url)
        shareItems = [url]
        showingShareSheet = true
        isProcessing = false
    }

    /// 現在のコンテナ実寸とユーザー指定 px から、
    /// プレビューで実際に使うフレーム実寸(pt)を再計算する
    private func recalcFramePt(container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }
        let scale = UIScreen.main.scale
        let desiredW = CGFloat(targetWidthPx)/scale // 指定px → pt
        let desiredH = CGFloat(targetHeightPx)/scale

        let frameRatio = desiredW/desiredH
        let screenRatio = container.width/container.height

        if frameRatio > screenRatio {
            let w = min(desiredW, container.width)
            return CGSize(width: w, height: w/frameRatio)
        } else {
            let h = min(desiredH, container.height)
            return CGSize(width: h * frameRatio, height: h)
        }
    }

    /// プレビュー時の state（offset, zoomScale, rotationAngle, scaleX/Y）を
    private func exportImage() -> UIImage? {
        guard let src = silhouetteImage?.normalized() else { return nil }

        let outW = CGFloat(targetWidthPx)
        let outH = CGFloat(targetHeightPx)

        // フレーム実寸（pt）を取得。ダメなら式で再計算してフォールバック
        var framePt = previewFramePt
        if framePt.width < 10 || framePt.height < 10 || framePt == .init(width: 100, height: 100) {
            framePt = recalcFramePt(container: previewContainerPt)
        }
        guard framePt.width > 0, framePt.height > 0 else { return nil }

        // pt→px 係数（X/Y 別）
        let kx = outW/framePt.width
        let ky = outH/framePt.height

        // 画像サイズ（px）
        let imgPxW = src.size.width * src.scale
        let imgPxH = src.size.height * src.scale

        // プレビューと同じ aspectFit（px基準にして OK）
        let fitScalePx = min(outW/imgPxW, outH/imgPxH)
        let totalScaleX = fitScalePx * zoomScale
        let totalScaleY = fitScalePx * zoomScale

        // ドラッグ量：pt → px
        let offsetXPx = dragOffset.width * kx
        let offsetYPx = dragOffset.height * ky

        let fmt = UIGraphicsImageRendererFormat()
        fmt.opaque = false
        fmt.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outW, height: outH), format: fmt)

        return renderer.image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: outW/2, y: outH/2)
            c.translateBy(x: offsetXPx, y: offsetYPx)
            c.scaleBy(x: totalScaleX, y: totalScaleY)
            c.translateBy(x: -imgPxW/2, y: -imgPxH/2)
            src.draw(in: CGRect(x: 0, y: 0, width: imgPxW, height: imgPxH))
        }
    }
}

extension UIApplication {
    /// キーボードを閉じる
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension UIImage {
    /// orientation が .up 以外の場合は再描画して .up にする
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }
}
