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
//
//    // 上限超過アラート表示用
//    @State private var showLimitAlert = false
//    
//    
//    @State private var cellFrames: [String: CGRect] = [:]
//    @State private var isSelecting = false
//    @State private var dragVisitedIDs: Set<String> = [] // ← ここ
//    @State private var dragDirection: DragDirection? = nil
//
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // メインのコンテンツ（スクロール領域）
//                if viewModel.assets.isEmpty {
//                    // 写真がまだない場合
//                    VStack {
//                        Spacer()
//                        ProgressView("Loading images...")
//                        Spacer()
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .background(Color.white.opacity(0.7))
//
//                } else {
//                    // 写真がある場合は LazyVGrid で表示
//                    ScrollView {
//                        let spacing: CGFloat = 1.0
//                        let columnsCount = 3
//                        let layout = LayoutConfiguration(
//                            totalWidth: UIScreen.main.bounds.width,
//                            columnsCount: columnsCount,
//                            spacing: spacing
//                        )
//
//                        LazyVGrid(
//                            columns: makeColumns(spacing: layout.spacing, count: layout.columnsCount),
//                            spacing: layout.spacing
//                        ) {
//                            ForEach(viewModel.assets, id: \.localIdentifier) { asset in
//                                MultiSelectableAssetThumbnail(
//                                    asset: asset,
//                                    isSelected: selectedAssetIDs.contains(asset.localIdentifier),
//                                    onToggle: { toggleSelection(for: asset) }
//                                )
//                                .frame(width: layout.cellSide, height: layout.cellSide)
//                                .aspectRatio(1, contentMode: .fill)
//                                .clipped()
//                                .background(
//                                    GeometryReader { geo in
//                                        Color.clear
//                                            .preference(
//                                                key: AssetFrameKey.self,
//                                                value: [asset.localIdentifier: geo.frame(in: .named("gallery"))]
//                                            )
//                                    }
//                                )
//                                .contentShape(Rectangle())
//                                .onTapGesture {
//                                    if isSelecting || !selectedAssetIDs.isEmpty {
//                                        // ドラッグモード中、または既に何か選択済み → トグル
//                                        toggleSelection(for: asset)
//                                    } else {
//                                        // 完全なタップ → ナビゲーション
//                                        navigationPath.append(.init(id: .SETTING)) // 例: NavigationLink 相当
//                                    }
//                                }
//                            }
//
////                            ForEach(viewModel.assets, id: \.localIdentifier) { asset in
////                                Group {
////                                    if selectedAssetIDs.isEmpty {
////                                        NavigationLink(destination: CompressionSettingView(asset: asset)) {
////                                            MultiSelectableAssetThumbnail(
////                                                asset: asset,
////                                                isSelected: false,
////                                                onToggle: {
////                                                    selectedAssetIDs.insert(asset.localIdentifier)
////                                                }
////                                            )
////                                        }
////                                    } else {
////                                        MultiSelectableAssetThumbnail(
////                                            asset: asset,
////                                            isSelected: selectedAssetIDs.contains(asset.localIdentifier),
////                                            onToggle: {
////                                                toggleSelection(for: asset)
////                                            }
////                                        )
////                                    }
////                                }
////                                .frame(width: layout.cellSide, height: layout.cellSide)
////                                .aspectRatio(1, contentMode: .fill)
////                                .clipped()
////                                // ← ここを ifなしで必ず付ける
////                                .background(
////                                    GeometryReader { geo in
////                                        Color.clear
////                                            .preference(
////                                                key: AssetFrameKey.self,
////                                                value: [asset.localIdentifier:
////                                                    geo.frame(in: .named("gallery"))]
////                                            )
////                                    }
////                                )
////                            }
//                        } // : LazyGlid
//                    } // : ScrollView
//                    .scrollDisabled(isSelecting)
//                    .coordinateSpace(name: "gallery")
//                    .onPreferenceChange(AssetFrameKey.self) { cellFrames = $0 }
////                    .gesture(
////                        LongPressGesture(minimumDuration: 0.1)
////                            .onEnded { _ in
////                                isSelecting = true
////                                dragVisitedIDs.removeAll() // 念のためクリアしておく
////                            }
////                    )
//                    .highPriorityGesture(
//                        LongPressGesture(minimumDuration: 0.03)
//                            .sequenced(before: DragGesture(minimumDistance: 0))
//                            .onChanged { value in
//                                switch value {
//                                case .first(true):
//                                    isSelecting = true
//                                    dragVisitedIDs.removeAll()
//                                case .second(true, let drag?):
//                                    let loc = drag.location
//                                    for (id, frame) in cellFrames {
//                                        guard frame.contains(loc), !dragVisitedIDs.contains(id) else { continue }
//                                        dragVisitedIDs.insert(id)
//                                        if let asset = viewModel.assets.first(where: { $0.localIdentifier == id }) {
//                                            toggleSelection(for: asset)
//                                        }
//                                    }
//                                default:
//                                    break
//                                }
//                            }
//                            .onEnded { _ in
//                                isSelecting = false
//                                dragVisitedIDs.removeAll()
//                            }
//                    )
//
////                    .highPriorityGesture(
////                    .simultaneousGesture(
////                        print("ここにきました")
////                        DragGesture(minimumDistance: 0)
////                            .onChanged { value in
////                                guard isSelecting else { return }
////                                for (id, frame) in cellFrames {
////                                    // まだ訪れていないセルで、ドラッグ座標が含まれる場合のみ
////                                    if frame.contains(value.location),
////                                       !dragVisitedIDs.contains(id),
////                                       let asset = viewModel.assets.first(where: { $0.localIdentifier == id }) {
////                                        dragVisitedIDs.insert(id) // 以降このセルは無視
////                                        toggleSelection(for: asset) // ON/OFF 切り替え
////                                    }
////                                }
////                            }
////                            .onEnded { _ in
////                                isSelecting = false
////                                dragVisitedIDs.removeAll() // セッション終了でクリア
////                            }
////                    )
//                }
//                // フッター
//                multiSelectFooter
//            }
//            // ナビゲーションバーのタイトル
//            .navigationBarTitle(selectedAlbum?.title ?? "アルバム", displayMode: .inline)
//            // ナビゲーションバー右のアイコン (フォルダアイコンでアルバム選択)
//            .navigationBarIconSetting(name: "folder",
//                                      isEnabled: true,
//                                      iconPosition: .trailing,
//                                      action: onTappedIcon)
//            // エラーアラート
//            .alert(
//                "写真は最大10枚まで選択できます",
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
//    private func onTappedIcon() {
//        showingAlbumSelector.toggle()
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
//            Button("選択解除") {
//                deselectAll()
//            }
//            .disabled(selectedAssetIDs.isEmpty)
//            Spacer()
////            Button("すべて選択") {
////                selectAll()
////            }
////            Spacer()
//            // 選択したアセットの配列を使って MultiCompressionSettingView へ遷移
//            NavigationLink(destination: MultiCompressionSettingView(assets: selectedAssets())) {
//                Text("\(selectedAssetIDs.count) 枚選択")
//            }
//            .disabled(selectedAssetIDs.isEmpty)
//        }
//        .padding()
//        .background(Color(UIColor.systemGray6))
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
