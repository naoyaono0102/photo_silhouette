////
////  InitialView.swift
////  ToDoList
////
////  Created by 尾野順哉 on 2025/03/21.
////
//
//import Photos
//import SwiftUI
//
//// 写真一覧
//struct GalleryView: View {
//    @StateObject private var viewModel = PhotoLibraryViewModel()
//    @Binding var navigationPath: [NavigationItem]
//    
//    @State private var selectedAlbum: AlbumInfo?
//    @State private var showingAlbumSelector = false
//    
//    // 複数選択用の状態（初期は空＝未選択）
//    @State private var selectedAssetIDs: Set<String> = []
//    @State private var shouldRangeSelectOn = false // ← 追加
//    
//    // 上限超過アラート表示用
//    @State private var showLimitAlert = false
//    
//    @State private var cellFrames: [String: CGRect] = [:]
//    @State private var isSelecting = false
//    @State private var dragVisitedIDs: Set<String> = [] // ← ここ
//    
//    // ドラッグの向き判定
//    @State private var dragOrientation: DragOrientation = .none
//    @State private var dragStartIndex: Int? = nil
//    @State private var originalSelectedBeforeDrag: Set<String> = []
//    
//    // すでにトグル処理したセルの集合
//    @State private var hoverSet: Set<String> = []
//    
//    @State private var dragStartID: String? = nil // 追加
//    
//    // 列数を ViewModel から引けるなら使ってください
//    private let columnsCount = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 3
//    
//    // — 追加 —
//    @State private var authStatus: PHAuthorizationStatus = .notDetermined
//    
//    private enum DragOrientation {
//        case none // 未判定
//        case scroll // スクロールモード
//        case toggle // セル単位トグルモード
//        case rangeSelection // 範囲選択モード
//    }
//    
//    var body: some View {
//        NavigationView {
//            Group {
//                switch authStatus {
//                case .authorized, .limited:
//                    // 権限 OK → 既存の UI
//                    contentView
//                case .notDetermined:
//                    // リクエスト中はローディング
//                    permissionView
//                default:
//                    // 拒否中／制限中 → 設定リンクを表示
//                    permissionView
//                }
//            }
//            // … ナビゲーションバーやアラート設定 …
//            .onAppear(perform: checkPhotoLibraryPermission)
//            //            VStack(spacing: 0) {
//            //                // メインのコンテンツ（スクロール領域）
//            //                if viewModel.assets.isEmpty {
//            //                    // 写真がまだない場合
//            //                    VStack {
//            //                        Spacer()
//            //                        ProgressView("LOADING_IMAGES")
//            //                        Spacer()
//            //                    }
//            //                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            //                    .background(Color("BackgroundColor"))
//            //
//            //                } else {
//            //                    // 写真がある場合は一覧を表示
//            //                    gridView
//            //                }
//            //
//            //                // フッター
//            //                multiSelectFooter
//            //            }
//            // ナビゲーションバーのタイトル
//            .navigationBarSetting(title: selectedAlbum?.title ?? "", isVisible: true)
//            // ナビゲーションバー右のアイコン (フォルダアイコンでアルバム選択)
//            .navigationBarIconSetting(name: "folder",
//                                      isEnabled: true,
//                                      iconPosition: .trailing,
//                                      action: onTappedAlbumIcon)
//            // ナビゲーションバー左のアイコン
//            .navigationBarIconSetting(name: "gearshape",
//                                      isEnabled: true,
//                                      iconPosition: .leading,
//                                      action: onTappedSettingIcon)
//            // エラーアラート
//            .alert(
//                "MAX_SELECTION_ALERT",
//                isPresented: $showLimitAlert
//            ) {
//                Button("OK", role: .cancel) {}
//            }
//            // シート：アルバム選択
//            .sheet(isPresented: $showingAlbumSelector, onDismiss: {
//                if let album = selectedAlbum {
//                    viewModel.loadAssets(for: album)
//                }
//            }) {
//                AlbumSelectorView(albums: viewModel.albums, selectedAlbum: $selectedAlbum)
//            }
//            .onChange(of: selectedAlbum) { newValue in
//                if let album = newValue {
//                    viewModel.loadAssets(for: album)
//                }
//            }
//            .onChange(of: viewModel.albums) { albums in
//                if selectedAlbum == nil, !albums.isEmpty {
//                    // 「最近の項目」という名前を含むものがあればそちらを優先
//                    selectedAlbum = albums.first(where: { $0.title.contains("最近") }) ?? albums.first
//                    if let album = selectedAlbum {
//                        viewModel.loadAssets(for: album)
//                    }
//                }
//            }
//            .onAppear {
//                // 初期ロードや再表示の際に更新
//                if let album = selectedAlbum {
//                    viewModel.loadAssets(for: album)
//                } else if !viewModel.albums.isEmpty {
//                    selectedAlbum = viewModel.albums.first(where: { $0.title.contains("最近") }) ?? viewModel.albums.first
//                    if let album = selectedAlbum {
//                        viewModel.loadAssets(for: album)
//                    }
//                }
//            }
//        }
//        .navigationViewStyle(StackNavigationViewStyle())
//    }
//    
//    // MARK: — 抽出した既存 UI
//    
//    private var contentView: some View {
//        VStack(spacing: 0) {
//            if viewModel.assets.isEmpty {
//                // … Loading / empty state …
//            } else {
//                gridView
//            }
//            multiSelectFooter
//        }
//    }
//    
//    // MARK: — 許可がない場合に出すビュー
//    
//    private var permissionView: some View {
//        VStack(spacing: 16) {
//            Spacer()
//            Text("PERMISSION_PHOTO_LIBRARY_DENIED")
//                .multilineTextAlignment(.center)
//            Button("BUTTON_OPEN_SETTINGS") {
//                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
//                UIApplication.shared.open(url)
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 10)
//            .background(.blue)
//            .foregroundColor(.white)
//            .cornerRadius(8)
//            Spacer()
//        }
//        .padding()
//    }
//    
//    /// onAppear で呼び出す
//    private func checkPhotoLibraryPermission() {
//        let current: PHAuthorizationStatus = if #available(iOS 14, *) {
//            PHPhotoLibrary.authorizationStatus(for: .readWrite)
//        } else {
//            PHPhotoLibrary.authorizationStatus()
//        }
//        authStatus = current
//        
//        switch current {
//        case .notDetermined:
//            // 初回ならリクエスト
//            requestPhotoLibraryAuth()
//        case .authorized, .limited:
//            // 許可済みならデータロード
//            viewModel.loadAssets(for: selectedAlbum)
//        default:
//            // 拒否中は何もしない（permissionView が出る）
//            break
//        }
//    }
//    
//    /// 権限リクエスト
//    private func requestPhotoLibraryAuth() {
//        if #available(iOS 14, *) {
//            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
//                DispatchQueue.main.async {
//                    authStatus = status
//                    if status == .authorized || status == .limited {
//                        viewModel.loadAssets(for: selectedAlbum)
//                    }
//                }
//            }
//        } else {
//            PHPhotoLibrary.requestAuthorization { status in
//                DispatchQueue.main.async {
//                    authStatus = status
//                    if status == .authorized {
//                        viewModel.loadAssets(for: selectedAlbum)
//                    }
//                }
//            }
//        }
//    }
//    
//    // MARK: — 切り出した ScrollView + LazyVGrid
//    
//    private var gridView: some View {
//        ScrollView {
//            let spacing: CGFloat = 1
//            let counts: Int = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 3
//            let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: counts)
//            LazyVGrid(columns: columns, spacing: spacing) {
//                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
//                    gridCell(for: asset, counts: counts, spacing: spacing)
//                }
//            }
//        }
//        // 長押し中のみスクロールを禁止
//        // dragOrientation が horizontal のときのみスクロールを止める
//        //        .scrollDisabled(dragOrientation == .horizontal || dragOrientation == .vertical)
//        
//        .coordinateSpace(name: "gallery")
//        //        .scrollDisabled(isSelecting)               // isSelecting=true 時のみスクロール禁止
//        .scrollDisabled(dragOrientation == .toggle || dragOrientation == .rangeSelection)
//        .gesture(longPressSelectionGesture) // 長押しで選択モード
//        .simultaneousGesture(dragSelectionGesture) // 選択モード時のドラッグを同時受け取り
//        .onPreferenceChange(AssetFrameKey.self) { cellFrames = $0 }
//    }
//    
//    private func gridCell(for asset: PHAsset, counts: Int, spacing: CGFloat) -> some View {
//        let id = asset.localIdentifier
//        
//        return Group {
//            if selectedAssetIDs.isEmpty {
//                NavigationLink(
//                    destination: CompressionSettingView(
//                        asset: asset
//                    )) {
//                        MultiSelectableAssetThumbnail(
//                            asset: asset,
//                            isSelected: false,
//                            onToggle: { selectedAssetIDs.insert(id) }
//                        )
//                    }
//            } else {
//                MultiSelectableAssetThumbnail(
//                    asset: asset,
//                    isSelected: selectedAssetIDs.contains(id),
//                    onToggle: { toggleSelection(for: asset) }
//                )
//            }
//        }
//        .frame(
//            width: UIScreen.main.bounds.width / CGFloat(counts) - spacing,
//            height: UIScreen.main.bounds.width / CGFloat(counts) - spacing
//        )
//        .clipped()
//        .background(
//            GeometryReader { geo in
//                Color.clear
//                    .preference(
//                        key: AssetFrameKey.self,
//                        value: [id: geo.frame(in: .named("gallery"))]
//                    )
//            }
//        )
//    }
//    
//    // MARK: - ジェスチャー定義を切り出し
//    
//    // MARK: — 長押しで選択モードに入る
//    
//    private var longPressSelectionGesture: some Gesture {
//        LongPressGesture(minimumDuration: 0.1)
//            .onEnded { _ in
//                isSelecting = true
//                dragOrientation = .none
//                dragStartIndex = nil
//                originalSelectedBeforeDrag = selectedAssetIDs
//                hoverSet.removeAll()
//            }
//    }
//    
//    // MARK: — ドラッグで範囲選択 or セル単位トグル or スクロール
//    
//    private var dragSelectionGesture: some Gesture {
//        DragGesture(minimumDistance: 5)
//            .onChanged { value in
//                let dx = value.translation.width
//                let dy = value.translation.height
//                
//                // —— ① 初回判定 ——
//                if dragOrientation == .none {
//                    if abs(dx) > abs(dy) {
//                        dragOrientation = .toggle
//                        originalSelectedBeforeDrag = selectedAssetIDs
//                        dragStartIndex = index(at: value.startLocation)
//                    } else {
//                        dragOrientation = .scroll
//                    }
//                }
//                // —— ② toggle 中に「垂直移動 or 行をまたいだ」ら rangeSelection ——
//                else if dragOrientation == .toggle {
//                    var shouldSwitch = false
//                    
//                    // 1) 十分な垂直移動で判定
//                    if dy > 20 {
//                        shouldSwitch = true
//                    }
//                    // 2) 行番号が違えば強制的に矩形選択
//                    else if
//                        let start = dragStartIndex,
//                        let end = index(at: value.location),
//                        row(of: start) != row(of: end) {
//                        shouldSwitch = true
//                    }
//                    
//                    if shouldSwitch {
//                        dragOrientation = .rangeSelection
//                        // 範囲選択開始時に一回だけ ON/OFF を決定
//                        if let start = dragStartIndex {
//                            let startID = viewModel.assets[start].localIdentifier
//                            shouldRangeSelectOn = !originalSelectedBeforeDrag.contains(startID)
//                        }
//                    }
//                }
//                
//                let loc = value.location
//                
//                switch dragOrientation {
//                case .scroll:
//                    break // ScrollView に任せる
//                    
//                case .toggle:
//                    // 従来どおりセル単位でトグル
//                    if let idx = index(at: loc) {
//                        let id = viewModel.assets[idx].localIdentifier
//                        if !hoverSet.contains(id) {
//                            toggleSelectionById(id)
//                            hoverSet.insert(id)
//                        }
//                    }
//                    
//                case .rangeSelection:
//                    // 拘束なしに必ず「開始〜現在セルのインデックス範囲」を選択
//                    if let start = dragStartIndex,
//                       let end = index(at: loc) {
//                        let range = min(start, end) ... max(start, end)
//                        let idsInRange = Set(viewModel.assets[range].map { $0.localIdentifier })
//                        
//                        if shouldRangeSelectOn {
//                            // ON 操作：union
//                            let newSet = originalSelectedBeforeDrag.union(idsInRange)
//                            if newSet.count > 10 {
//                                showLimitAlert = true
//                            } else {
//                                selectedAssetIDs = newSet
//                            }
//                        } else {
//                            // OFF 操作：subtracting
//                            selectedAssetIDs = originalSelectedBeforeDrag.subtracting(idsInRange)
//                        }
//                    }
//                    
//                case .none:
//                    break
//                }
//            }
//            .onEnded { _ in
//                dragOrientation = .none
//                dragStartIndex = nil
//                hoverSet.removeAll()
//            }
//    }
//    
//    /// CGPoint から asset 配列の index を返す
//    private func index(at point: CGPoint) -> Int? {
//        guard let id = cellFrames.first(where: { $0.value.contains(point) })?.key else {
//            return nil
//        }
//        return viewModel.assets.firstIndex { $0.localIdentifier == id }
//    }
//    
//    /// インデックスから行番号を計算 (0-based)
//    private func row(of index: Int) -> Int {
//        index / columnsCount
//    }
//    
//    // ID だけでトグル
//    private func toggleSelectionById(_ id: String) {
//        if selectedAssetIDs.contains(id) {
//            selectedAssetIDs.remove(id)
//        } else {
//            // 追加しようとするとき
//            if selectedAssetIDs.count >= 10 {
//                showLimitAlert = true // 上限到達ならアラート
//            } else {
//                selectedAssetIDs.insert(id)
//            }
//        }
//    }
//    
//    // セルのフレームを収集する PreferenceKey を定義
//    private struct AssetFrameKey: PreferenceKey {
//        static var defaultValue: [String: CGRect] = [:]
//        static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
//            value.merge(nextValue(), uniquingKeysWith: { $1 })
//        }
//    }
//    
//    /// GridItem 配列を作成するヘルパー
//    private func makeColumns(spacing: CGFloat, count: Int) -> [GridItem] {
//        Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
//    }
//    
//    private func onTappedAlbumIcon() {
//        showingAlbumSelector.toggle()
//    }
//    
//    private func onTappedSettingIcon() {
//        navigationPath.append(.init(id: .SETTING))
//    }
//    
//    // *追加
//    /// 現在選択中の PHAsset 配列を返す
//    private func selectedAssets() -> [PHAsset] {
//        viewModel.assets.filter { selectedAssetIDs.contains($0.localIdentifier) }
//    }
//    
//    /// 指定されたアセットの選択状態をトグルする
//    private func toggleSelection(for asset: PHAsset) {
//        if selectedAssetIDs.contains(asset.localIdentifier) {
//            // すでに選択済み → 外す
//            selectedAssetIDs.remove(asset.localIdentifier)
//        } else {
//            // 上限チェック
//            if selectedAssetIDs.count >= 10 {
//                // 10 枚を超えようとした → アラートを出して何もしない
//                showLimitAlert = true
//            } else {
//                // 問題なければ選択に追加
//                selectedAssetIDs.insert(asset.localIdentifier)
//            }
//        }
//    }
//    
//    /// すべて選択する
//    private func selectAll() {
//        for asset in viewModel.assets {
//            selectedAssetIDs.insert(asset.localIdentifier)
//        }
//    }
//    
//    /// すべての選択を解除する
//    private func deselectAll() {
//        selectedAssetIDs.removeAll()
//    }
//    
//    /// 画面下部フッター（常に表示）
//    private var multiSelectFooter: some View {
//        HStack(spacing: 16) {
//            Button(action: deselectAll) {
//                Text("DESELECT")
//                // 選択があるときは赤、それ以外はグレー
//                    .foregroundColor(selectedAssetIDs.isEmpty ? .gray : .red)
//            }
//            .disabled(selectedAssetIDs.isEmpty)
//            .buttonStyle(.plain)
//            Spacer()
//            //            Button("すべて選択") {
//            //                selectAll()
//            //            }
//            //            Spacer()
//            // 選択したアセットの配列を使って MultiCompressionSettingView へ遷移
//            NavigationLink(destination: MultiCompressionSettingView(assets: selectedAssets())) {
//                //                Text("\(selectedAssetIDs.count) 枚選択")
//                Text(String(format: NSLocalizedString("SELECTED_COUNT", comment: ""), "\(selectedAssetIDs.count)"))
//                // 選択があるときは青、それ以外はグレー
//                    .foregroundColor(selectedAssetIDs.isEmpty ? .gray : .blue)
//            }
//            .disabled(selectedAssetIDs.isEmpty)
//            .buttonStyle(.plain)
//        }
//        .padding(.horizontal)
//        .padding(.top, 22)
//        .padding(.bottom, 22)
//        .background(Color("BackgroundColor"))
//    }
//}
//
///// GeometryReader 内でのレイアウト設定をまとめる構造体
//struct LayoutConfiguration {
//    let totalWidth: CGFloat
//    let columnsCount: Int
//    let spacing: CGFloat
//    
//    /// セル間の隙間の合計
//    var totalSpacing: CGFloat {
//        CGFloat(columnsCount - 1) * spacing
//    }
//    
//    /// 各セルの正方形にするための一辺の長さ
//    var cellSide: CGFloat {
//        (totalWidth - totalSpacing) / CGFloat(columnsCount)
//    }
//}
//
//struct GalleryView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            GalleryView(navigationPath: .constant([]))
//        }
//    }
//}
