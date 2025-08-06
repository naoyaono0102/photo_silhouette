// import Photos
// import SwiftUI
//
//// まず「PNG / JPEG」を選ぶための列挙型
// private enum ImageFormat: String, CaseIterable, Identifiable {
//    case png = "PNG"
//    case jpeg = "JPEG"
//
//    var id: String { rawValue }
//    // 拡張子として使いたい文字列
//    var fileExtension: String {
//        switch self {
//        case .png: return "png"
//        case .jpeg: return "jpg"
//        }
//    }
// }
//
// struct PhotoEditorView: View {
//    let asset: PHAsset
//    @Environment(\.presentationMode) private var presentationMode
//
//    @State private var image: UIImage?
//    @State private var scale: CGFloat = 1.0
//    @State private var lastScale: CGFloat = 1.0
//
//    @State private var borderWidth: CGFloat = 5.0
//    @State private var borderColor: Color = .white
//    @State private var backgroundColor: Color = .black
//
//    @State private var showingShareSheet = false
//    @State private var imageToShare: UIImage?
//    @State private var shareFilename: String = ""
//    @State private var shareItems: [Any] = []
//
//    /// GeometryReader 内で計算される「プレビュー円の直径 (ポイント単位)」を保持しておく
//    @State private var previewSide: CGFloat = 0
//
//    /// 画像のドラッグ量を一時的に保持 (ドラッグ中の offset)
//    @State private var currentOffset: CGSize = .zero
//    /// 画像の累積オフセット (過去のドラッグ結果を保持)
//    @State private var lastOffset: CGSize = .zero
//
//    /// 回転角度 (0〜360度). Angle 型で保持します
//    @State private var rotationAngle: Angle = .zero
//
//    // ← ここを追加：エクスポートフォーマットを保持する @State
//    @State private var exportFormat: ImageFormat = .png
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // 画像プレビュー（正方形に制限）
//            ZStack {
//                backgroundColor
//
//                if let image {
//                    GeometryReader { geometry in
//                        // プレビューで使う「円の直径 (pt)」を計算
//                        let side = min(geometry.size.width, geometry.size.height)
//
//                        // 「円 + 画像」を重ねた ZStack 全体にジェスチャーを付与
//                        ZStack {
//                            // (A) 背景色の円
//                            Circle()
//                                .fill(backgroundColor)
//                                .frame(width: side, height: side)
//
//                            // (B) 画像部分
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFill()
//                            // (1) プレビューでのズーム
//                                .scaleEffect(scale)
//                            // (2) プレビューでのオフセット(パン)
//                                .offset(
//                                    x: lastOffset.width + currentOffset.width,
//                                    y: lastOffset.height + currentOffset.height
//                                )
//                            // (3) プレビューでの回転 (Slider で制御)
//                                .rotationEffect(rotationAngle) // ← ジェスチャーではなく Slider で変化する
//                            // (4) 円形マスク
//                                .mask(
//                                    Circle()
//                                        .frame(width: side, height: side)
//                                )
//                            // (5) 枠線を重ねる
//                                .overlay(
//                                    Circle()
//                                        .strokeBorder(borderColor,
//                                                      lineWidth: borderWidth)
//                                        .frame(width: side, height: side)
//                                )
//                                .frame(width: side, height: side)
//                        }
//                        // 「円形のヒットテスト範囲」を設定
//                        .contentShape(Circle())
//                        // Drag
//                        .highPriorityGesture(
//                            DragGesture()
//                                .onChanged { value in
//                                    currentOffset = value.translation
//                                }
//                                .onEnded { value in
//                                    lastOffset.width += value.translation.width
//                                    lastOffset.height += value.translation.height
//                                    currentOffset = .zero
//                                }
//                        )
//                        // Pinch
//                        .simultaneousGesture(
//                            MagnificationGesture()
//                                .onChanged { value in
//                                    scale = lastScale * value
//                                }
//                                .onEnded { _ in
//                                    lastScale = scale
//                                }
//                        )
//                        // GPUキャッシュで描画を高速化
//                        .drawingGroup()
//
//                        .frame(width: side, height: side)
//                        .position(x: geometry.size.width / 2,
//                                  y: geometry.size.height / 2)
//                        .onAppear {
//                            previewSide = side
//                        }
//                        .onChange(of: side) { newSide in
//                            previewSide = newSide
//                        }
//                    }
//                } else {
//                    ProgressView()
//                }
//            }
//            .aspectRatio(1, contentMode: .fit) // ✅ プレビュー自体を正方形に制限
//            .frame(maxWidth: .infinity)
//            .background(backgroundColor)
//            .navigationBarIconSetting(name: "arrow.clockwise",
//                                      isEnabled: true,
//                                      iconPosition: .trailing,
//                                      action: reset)
//
//            // コントロールパネル
//            VStack {
//                HStack {
//                    Text("画像形式:")
//                    Picker("フォーマット", selection: $exportFormat) {
//                        ForEach(ImageFormat.allCases) { format in
//                            Text(format.rawValue).tag(format)
//                        }
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                }
//
//                HStack {
//                    Text("枠線の太さ")
//                    Slider(value: $borderWidth, in: 0 ... 100)
//                    Text(String(format: "%.0f", borderWidth))
//                }
//
//                HStack {
//                    Text("枠線の色")
//                    ColorPicker("", selection: $borderColor)
//                }
//
//                HStack {
//                    Text("背景色")
//                    ColorPicker("", selection: $backgroundColor)
//                }
//
//                HStack {
//                    Text("回転角度")
//                    Slider(
//                        value: Binding(
//                            get: { rotationAngle.degrees },
//                            set: { newDeg in
//                                rotationAngle = .degrees(newDeg)
//                            }
//                        ),
//                        in: 0 ... 360,
//                        step: 1
//                    )
//                    Text("\(Int(rotationAngle.degrees))°")
//                }
//            }
//            .padding()
//            .background(Color(UIColor.systemBackground))
//
//            // アクションボタン
//            HStack(spacing: 20) {
//                Button(action: saveImage) {
//                    Label("保存", systemImage: "square.and.arrow.down")
//                }
//                .frame(maxWidth: .infinity)
//                .buttonStyle(.borderedProminent)
//
//                Button(action: shareImage) {
//                    Label("共有", systemImage: "square.and.arrow.up")
//                }
//                .frame(maxWidth: .infinity)
//                .buttonStyle(.borderedProminent)
//            }
//            .padding(.horizontal)
//            .padding(.bottom)
//
//            Spacer()
//        }
//        .navigationBarTitle("写真編集", displayMode: .inline)
//        .sheet(isPresented: $showingShareSheet) {
//            if !shareItems.isEmpty {
//                ShareSheet(activityItems: shareItems)
//                    .presentationDetents([.medium])
//            }
//        }
//        .onAppear(perform: loadImage)
//    }
//
//    private var controlPanelHeight: CGFloat { 200 } // 必要に応じて調整
//
//    private var controlPanel: some View {
//        VStack {
//            HStack {
//                Text("枠線の太さ")
//                Slider(value: $borderWidth, in: 0 ... 100)
//                Text(String(format: "%.0f", borderWidth))
//            }
//
//            HStack {
//                Text("枠線の色")
//                ColorPicker("", selection: $borderColor)
//            }
//
//            HStack {
//                Text("背景色")
//                ColorPicker("", selection: $backgroundColor)
//            }
//
//            HStack(spacing: 20) {
//                Button(action: saveImage) {
//                    Label("保存", systemImage: "square.and.arrow.down")
//                }
//                .frame(maxWidth: .infinity)
//                .buttonStyle(.borderedProminent)
//
//                Button(action: shareImage) {
//                    Label("共有", systemImage: "square.and.arrow.up")
//                }
//                .frame(maxWidth: .infinity)
//                .buttonStyle(.borderedProminent)
//            }
//        }
//        .padding()
//        .background(Color(UIColor.systemBackground))
//    }
//
//    // MARK: — 写真読み込み
//
//    private func loadImage() {
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .highQualityFormat
//        options.isSynchronous = false
//        options.isNetworkAccessAllowed = true
//
//        PHImageManager.default().requestImage(for: asset,
//                                              targetSize: PHImageManagerMaximumSize,
//                                              contentMode: .aspectFill,
//                                              options: options) { result, _ in
//            if let result {
//                image = result
//            }
//        }
//    }
//
//    // MARK: — リセット処理
//
//    /// リセットボタンを押したときに呼び出す関数
//    private func reset() {
//        // ズーム関連
//        scale = 1.0
//        lastScale = 1.0
//
//        // パン（平行移動）関連
//        currentOffset = .zero
//        lastOffset = .zero
//
//        // 回転関連 (スライダーで制御している場合)
//        rotationAngle = .zero
//
//        // 枠線の太さは初期値（例: 5）に戻す
//        borderWidth = 5.0
//
//        // 必要であれば、枠線色や背景色も初期値に戻す
//        // borderColor = .white
//        // backgroundColor = .black
//
//        // 必要であれば、プレビューサイズも初期化しておく（通常 onAppear で再設定されるので不要）
//        // previewSide = 0
//    }
//
//    // MARK: — 保存処理
//
//    //    private func saveImage() {
//    //        guard let rendered = renderImage() else { return }
//    //        // フォトライブラリに保存する
//    //        UIImageWriteToSavedPhotosAlbum(rendered, nil, nil, nil)
//    //    }
//
//    private func saveImage() {
//        guard let rendered = renderImage() else { return }
//
//        // ① まず、画像データ (Data) をフォーマットに応じて準備する
//        let imageData: Data? = switch exportFormat {
//        case .png:
//            rendered.pngData()
//        case .jpeg:
//            // 圧縮品質は 1.0（高品質）に設定
//            rendered.jpegData(compressionQuality: 1.0)
//        }
//        guard let data = imageData else { return }
//
//        // ② PHPhotoLibrary 経由で「生の Data を PNG/JPEG として保存」
//        PHPhotoLibrary.shared().performChanges({
//            let creationRequest = PHAssetCreationRequest.forAsset()
//            let options = PHAssetResourceCreationOptions()
//            // JPEG / PNG として正しくリソースを追加
//            creationRequest.addResource(
//                with: .photo,
//                data: data,
//                options: options
//            )
//        }, completionHandler: { _, error in
//            if let error {
//                print("Error saving to Photo Library: \(error)")
//            } else {
//                print("Saved to Photo Library as \(exportFormat.rawValue)")
//            }
//        })
//    }
//
//    // MARK: — 共有処理 (フォーマットを反映)
//
//    private func shareImage() {
//        guard let rendered = renderImage() else { return }
//
//        // ① 共有用の一時ファイル名を組み立てる
//        let ext = exportFormat.fileExtension
//        let filename = "\(Date().timeIntervalSince1970)_\(UUID().uuidString.prefix(8)).\(ext)"
//        // /tmp ディレクトリに書き出す
//        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
//
//        // ② 画像データ (Data) を作成し、一時ファイルに書き出す
//        let imageData: Data? = switch exportFormat {
//        case .png:
//            rendered.pngData()
//        case .jpeg:
//            rendered.jpegData(compressionQuality: 1.0)
//        }
//        if let data = imageData {
//            do {
//                try data.write(to: tmpURL, options: .atomic)
//            } catch {
//                print("Error writing temporary file: \(error)")
//                return
//            }
//        } else {
//            return
//        }
//
//        // ③ shareItems にその URL を渡してシェアシートを開く
//        shareItems = [tmpURL]
//        showingShareSheet = true
//    }
//
//    // MARK: — 描画処理（円形画像＋枠線＋背景）
//
//    private func renderImage() -> UIImage? {
//        guard let image else { return nil }
//
//        // (1) UIImage の「ポイント空間サイズ」と「scale」を取得
//        let imageSizeInPoints = image.size
//        let imageScaleFactor = image.scale
//
//        // (2) 正方形にクロップするための「一辺 (ポイント)」
//        let sideInPoints = min(imageSizeInPoints.width, imageSizeInPoints.height)
//
//        // (3) プレビューの scaledToFill() と同じ数式で drawSizeInPoints を求める
//        let imageAspect = imageSizeInPoints.width / imageSizeInPoints.height
//        let canvasAspect = CGFloat(1.0)
//        let drawSizeInPoints: CGSize = {
//            if imageAspect > canvasAspect {
//                return CGSize(width: sideInPoints * imageAspect,
//                              height: sideInPoints)
//            } else {
//                return CGSize(width: sideInPoints,
//                              height: sideInPoints / imageAspect)
//            }
//        }()
//
//        // (4) scaleEffect(scale) を適用したサイズ (pt)
//        let zoomedDrawSizeInPoints = CGSize(
//            width: drawSizeInPoints.width * scale,
//            height: drawSizeInPoints.height * scale
//        )
//
//        // (5) プレビューのオフセット (pt)
//        let previewOffsetInPoints = CGSize(
//            width: lastOffset.width + currentOffset.width,
//            height: lastOffset.height + currentOffset.height
//        )
//
//        // (6) 回転角度 (ラジアンに変換)
//        let angleInRadians = CGFloat(rotationAngle.radians)
//
//        // (7) 「プレビュー → 保存キャンバス」へのオフセット変換係数
//        guard previewSide > 0 else { return nil }
//        let offsetScaleFactor = sideInPoints / previewSide
//        let renderOffsetInPoints = CGSize(
//            width: previewOffsetInPoints.width * offsetScaleFactor,
//            height: previewOffsetInPoints.height * offsetScaleFactor
//        )
//
//        // (8) キャンバス中心に置いてからオフセットをかける原点 (pt)
//        let canvasSizeInPoints = CGSize(width: sideInPoints, height: sideInPoints)
//        let centerX = (canvasSizeInPoints.width - zoomedDrawSizeInPoints.width) / 2
//        let centerY = (canvasSizeInPoints.height - zoomedDrawSizeInPoints.height) / 2
//        let rawOrigin = CGPoint(x: centerX + renderOffsetInPoints.width,
//                                y: centerY + renderOffsetInPoints.height)
//
//        // (9) UIGraphicsImageRenderer の準備
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = UIScreen.main.scale
//
//        let renderer = UIGraphicsImageRenderer(
//            size: canvasSizeInPoints,
//            format: format
//        )
//
//        return renderer.image { context in
//            let ctx = context.cgContext
//
//            // (A) 背景色を敷き詰め
//            ctx.setFillColor(UIColor(backgroundColor).cgColor)
//            ctx.fill(CGRect(origin: .zero, size: canvasSizeInPoints))
//
//            // (B) 回転 + 円形クリップ (save→transform→clip→draw→restore)
//            ctx.saveGState()
//
//            //   (B1) キャンバス中心で回転
//            let cx = canvasSizeInPoints.width / 2
//            let cy = canvasSizeInPoints.height / 2
//            ctx.translateBy(x: cx, y: cy)
//            ctx.rotate(by: angleInRadians)
//            ctx.translateBy(x: -cx, y: -cy)
//
//            //   (B2) 円形クリップ
//            let circleRect = CGRect(origin: .zero, size: canvasSizeInPoints)
//            ctx.addEllipse(in: circleRect)
//            ctx.clip()
//
//            // (C) scaledToFill + scaleEffect + offset + rotation を反映して描画
//            image.draw(
//                in: CGRect(origin: rawOrigin,
//                           size: zoomedDrawSizeInPoints)
//            )
//
//            // (D) マスク＆回転を解除
//            ctx.restoreGState()
//
//            // (E) 枠線を描画
//            let borderRatio: CGFloat = {
//                guard previewSide > 0 else { return 0 }
//                return borderWidth / previewSide
//            }()
//            let borderWidthInPoints = borderRatio * canvasSizeInPoints.width
//
//            if borderWidthInPoints > 0 {
//                ctx.setStrokeColor(UIColor(borderColor).cgColor)
//                ctx.setLineWidth(borderWidthInPoints)
//                ctx.strokeEllipse(
//                    in: circleRect.insetBy(
//                        dx: borderWidthInPoints / 2,
//                        dy: borderWidthInPoints / 2
//                    )
//                )
//            }
//        }
//    }
//
//    //    private func renderImage() -> UIImage? {
//    //        guard let image else { return nil }
//    //
//    //        // (1) UIImage の「ポイント空間サイズ」と「scale」を取得
//    //        let imageSizeInPoints = image.size // 例：2000×1500 pt
//    //        let imageScaleFactor = image.scale // 1.0 か 2.0 など
//    //
//    //        // (2) 正方形にクロップするための「一辺 (ポイント)」
//    //        let sideInPoints = min(imageSizeInPoints.width, imageSizeInPoints.height)
//    //        // 例： (2000,1500) → 1500pt
//    //
//    //        // (3) プレビューの scaledToFill() と同じ数式で drawSizeInPoints を求める
//    //        let imageAspect = imageSizeInPoints.width / imageSizeInPoints.height
//    //        let canvasAspect = CGFloat(1.0)
//    //        let drawSizeInPoints: CGSize = {
//    //            if imageAspect > canvasAspect {
//    //                return CGSize(width: sideInPoints * imageAspect,
//    //                              height: sideInPoints)
//    //            } else {
//    //                return CGSize(width: sideInPoints,
//    //                              height: sideInPoints / imageAspect)
//    //            }
//    //        }()
//    //        // 例： (2000/1500 = 1.333) → drawSizeInPoints = (1500×1.333,1500) = (2000,1500)
//    //
//    //        // (4) scaleEffect(scale) を適用したサイズ (pt)
//    //        let zoomedDrawSizeInPoints = CGSize(
//    //            width: drawSizeInPoints.width * scale,
//    //            height: drawSizeInPoints.height * scale
//    //        )
//    //        // 例： scale = 1.2 → (2400,1800) pt
//    //
//    //        // (5) プレビューのオフセット (pt)
//    //        let previewOffsetInPoints = CGSize(
//    //            width: lastOffset.width + currentOffset.width,
//    //            height: lastOffset.height + currentOffset.height
//    //        )
//    //        // 例： (x:20 pt, y:-15 pt)
//    //
//    //        // (6) 回転角度 (ラジアンに変換)
//    //        let angleInRadians = CGFloat(rotationAngle.radians)
//    //        // ※ rotationAngle は Slider で 0°〜360° の範囲で操作されています
//    //
//    //        // (7) 「プレビュー → 保存キャンバス」へのオフセット変換係数
//    //        guard previewSide > 0 else { return nil }
//    //        let offsetScaleFactor = sideInPoints / previewSide
//    //        let renderOffsetInPoints = CGSize(
//    //            width: previewOffsetInPoints.width * offsetScaleFactor,
//    //            height: previewOffsetInPoints.height * offsetScaleFactor
//    //        )
//    //        // 例： previewSide=300, sideInPoints=1500 → factor=5.0
//    //        //     renderOffsetInPoints = (20×5, -15×5) = (100, -75) pt
//    //
//    //        // (8) キャンバス中心に置いてからオフセットをかける原点 (pt)
//    //        let canvasSizeInPoints = CGSize(width: sideInPoints, height: sideInPoints)
//    //        let centerX = (canvasSizeInPoints.width - zoomedDrawSizeInPoints.width) / 2
//    //        let centerY = (canvasSizeInPoints.height - zoomedDrawSizeInPoints.height) / 2
//    //        let rawOrigin = CGPoint(x: centerX + renderOffsetInPoints.width,
//    //                                y: centerY + renderOffsetInPoints.height)
//    //        // 例： rawOrigin = (-450 + 100, -150 - 75) = (-350, -225) pt
//    //
//    //        // (9) UIGraphicsImageRenderer の準備
//    //        let format = UIGraphicsImageRendererFormat()
//    //        format.scale = UIScreen.main.scale // デバイスの Retina スケールを使う
//    //
//    //        let renderer = UIGraphicsImageRenderer(
//    //            size: canvasSizeInPoints,
//    //            format: format
//    //        )
//    //        // 内部では 1500pt × 2.0 scale = 3000px のバッファを生成
//    //
//    //        return renderer.image { context in
//    //            let ctx = context.cgContext
//    //
//    //            // (A) 背景色を敷き詰め
//    //            ctx.setFillColor(UIColor(backgroundColor).cgColor)
//    //            ctx.fill(CGRect(origin: .zero, size: canvasSizeInPoints))
//    //
//    //            // (B) 回転 + 円形クリップの状態を作る (save → transform → clip → draw → restore)
//    //            ctx.saveGState()
//    //
//    //            //  (B1) 「キャンバス中心で回転」をかける
//    //            let cx = canvasSizeInPoints.width / 2
//    //            let cy = canvasSizeInPoints.height / 2
//    //            ctx.translateBy(x: cx, y: cy)
//    //            ctx.rotate(by: angleInRadians)
//    //            ctx.translateBy(x: -cx, y: -cy)
//    //
//    //            //  (B2) 円形クリップをかける
//    //            let circleRect = CGRect(origin: .zero, size: canvasSizeInPoints)
//    //            ctx.addEllipse(in: circleRect)
//    //            ctx.clip()
//    //
//    //            // (C) プレビューと同じ「scaledToFill + scaleEffect + offset + rotation」を反映して描画
//    //            image.draw(
//    //                in: CGRect(origin: rawOrigin,
//    //                           size: zoomedDrawSizeInPoints)
//    //            )
//    //
//    //            // (D) マスク＆回転を解除
//    //            ctx.restoreGState()
//    //
//    //            // (E) 枠線を描画
//    //            let borderRatio: CGFloat = {
//    //                guard previewSide > 0 else { return 0 }
//    //                return borderWidth / previewSide
//    //            }()
//    //            let borderWidthInPoints = borderRatio * canvasSizeInPoints.width
//    //
//    //            if borderWidthInPoints > 0 {
//    //                ctx.setStrokeColor(UIColor(borderColor).cgColor)
//    //                ctx.setLineWidth(borderWidthInPoints)
//    //                ctx.strokeEllipse(
//    //                    in: circleRect.insetBy(
//    //                        dx: borderWidthInPoints / 2,
//    //                        dy: borderWidthInPoints / 2
//    //                    )
//    //                )
//    //            }
//    //        }
//    //    }
// }
