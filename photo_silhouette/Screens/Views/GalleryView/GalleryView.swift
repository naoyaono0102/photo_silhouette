//
//  GalleryView.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

import Photos
import SwiftUI


struct GalleryView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @Binding var navigationPath: [NavigationItem]
    @Environment(\.scenePhase) private var scenePhase // バックグラウンド→フォアグラウンド監視
    
    @State private var selectedAlbum: AlbumInfo?
    @State private var showingAlbumSelector = false
    
    // 複数選択用の状態（初期は空＝未選択）
    @State private var selectedAssetIDs: Set<String> = []
    @State private var shouldRangeSelectOn = false
    
    @State private var cellFrames: [String: CGRect] = [:]
    @State private var isSelecting = false
    
    // ─── カメラ関連の追加 ───
    /// カメラシートを表示するフラグ
    @State private var showingImagePicker: Bool = false
    /// 撮影した画像（カメラから返ってくる UIImage）を一時保持
    @State private var capturedImage: UIImage? = nil
    
    // 列数を UIDevice から判断
    private let columnsCount = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 3
    
    // — 追加 —
    @State private var authStatus: PHAuthorizationStatus = .notDetermined
    
    var body: some View {
        // ① Group { … } を変数に代入
        let baseView = Group {
            switch authStatus {
            case .authorized, .limited:
                // 権限 OK → 既存の UI
                contentView
            case .notDetermined:
                // リクエスト中はローディング
                permissionView
            default:
                // 拒否中／制限中 → 設定リンクを表示
                permissionView
            }
        }
        .onAppear(perform: checkPhotoLibraryPermission)
        
        // ② ナビゲーションバーのタイトルを設定
        let withNavBarTitle = baseView
            .navigationBarSetting(
                title: selectedAlbum?.title ?? "",
                isVisible: true
            )
        
        // ③ フォルダアイコン（アルバム選択）
        let withFolderIcon = withNavBarTitle
            .navigationBarIconSetting(
                name: "folder",
                isEnabled: true,
                iconPosition: .trailing,
                action: onTappedAlbumIcon
            )
        
        // ④ カメラアイコン
        let withCameraIcon = withFolderIcon
            .navigationBarIconSetting(
                name: "camera",
                isEnabled: true,
                iconPosition: .trailing,
                action: onTappedCameraIcon
            )
        
        // ⑤ 設定アイコン
        let withSettingIcon = withCameraIcon
            .navigationBarIconSetting(
                name: "gearshape",
                isEnabled: true,
                iconPosition: .leading,
                action: onTappedSettingIcon
            )
        
        // ⑥ アルバム選択用のシート
        let withAlbumSheet = withSettingIcon
            .sheet(
                isPresented: $showingAlbumSelector,
                onDismiss: {
                    if let album = selectedAlbum {
                        viewModel.loadAssets(for: album)
                    }
                }
            ) {
                AlbumSelectorView(
                    albums: viewModel.albums,
                    selectedAlbum: $selectedAlbum
                )
            }
        
        // ⑦ カメラ起動用のシート
        let withImagePickerSheet = withAlbumSheet
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: .camera) { pickedImage in
                    // クロージャの引数名「pickedImage」に合わせる
                    capturedImage = pickedImage
                    showingImagePicker = false
                    
                    // 撮影画像をナビゲーションパスに追加 → PhotoEditorView へ遷移
                    navigationPath.append(
                        NavigationItem(
                            id: .PHOTO_EDITOR,
                            capturedUIImage: pickedImage
                        )
                    )
                }
            }
        
        // ⑧ onChange / onAppear
        let withChanges = withImagePickerSheet
            .onChange(of: selectedAlbum) { newValue in
                if let album = newValue {
                    viewModel.loadAssets(for: album)
                }
            }
            .onChange(of: viewModel.albums) { albums in
                if selectedAlbum == nil, !albums.isEmpty {
                    selectedAlbum = albums.first(where: { $0.title.contains("最近") })
                        ?? albums.first
                    if let album = selectedAlbum {
                        viewModel.loadAssets(for: album)
                    }
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    if let album = selectedAlbum {
                        viewModel.loadAssets(for: album)
                    }
                }
            }
            .onAppear {
                if let album = selectedAlbum {
                    viewModel.loadAssets(for: album)
                } else if !viewModel.albums.isEmpty {
                    selectedAlbum = viewModel.albums.first(where: { $0.title.contains("最近") })
                        ?? viewModel.albums.first
                    if let album = selectedAlbum {
                        viewModel.loadAssets(for: album)
                    }
                }
            }
        
        // ⑨ NavigationView で囲み、最終的に返す
        return NavigationView {
            withChanges
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: — 抽出した既存 UI
    
    /// 権限 OK のときに表示するコンテンツ
    private var contentView: some View {
        VStack(spacing: 0) {
            if viewModel.assets.isEmpty {
                VStack {
                    Spacer()
                    Text("No Photos")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                gridView
            }
            multiSelectFooter
        }
    }
    
    /// 許可がない場合に出すビュー
    private var permissionView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("PERMISSION_PHOTO_LIBRARY_DENIED")
                .multilineTextAlignment(.center)
            Button("BUTTON_OPEN_SETTINGS") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            Spacer()
        }
        .padding()
    }
    
    /// ScrollView + LazyVGrid でギャラリーを表示
    private var gridView: some View {
        ScrollView {
            let spacing: CGFloat = 1
            let counts: Int = columnsCount
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: spacing),
                count: counts
            )
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                    gridCell(for: asset, counts: counts, spacing: spacing)
                }
            }
        }
        .coordinateSpace(name: "gallery")
    }
    
    private func gridCell(
        for asset: PHAsset,
        counts: Int,
        spacing: CGFloat
    ) -> some View {
        let id = asset.localIdentifier
        return NavigationLink(
            destination: PhotoEditorView(asset: asset)
        ) {
            MultiSelectableAssetThumbnail(
                asset: asset,
                isSelected: selectedAssetIDs.contains(id),
                onToggle: { toggleSelection(for: asset) }
            )
        }
        .frame(
            width: UIScreen.main.bounds.width / CGFloat(counts) - spacing,
            height: UIScreen.main.bounds.width / CGFloat(counts) - spacing
        )
        .clipped()
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: AssetFrameKey.self,
                        value: [id: geo.frame(in: .named("gallery"))]
                    )
            }
        )
    }
    
    /// すでに選択されているかトグルする
    private func toggleSelection(for asset: PHAsset) {
        let id = asset.localIdentifier
        if selectedAssetIDs.contains(id) {
            selectedAssetIDs.remove(id)
        } else {
            selectedAssetIDs.insert(id)
        }
    }
    
    /// 選択中の PHAsset 配列を返す
    private func selectedAssets() -> [PHAsset] {
        viewModel.assets.filter { selectedAssetIDs.contains($0.localIdentifier) }
    }
    
    /// 選択中のものをすべて解除
    private func deselectAll() {
        selectedAssetIDs.removeAll()
    }
    
    /// 選択中のアセットを削除（最近削除フォルダへ移動）
    private func deleteSelectedAssets() {
        let assetsToDelete = selectedAssets() as NSArray
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete)
        } completionHandler: { success, error in
            if let error {
                print("削除エラー:", error)
                return
            }
            if success {
                DispatchQueue.main.async {
                    selectedAssetIDs.removeAll()
                    if let album = selectedAlbum {
                        viewModel.loadAssets(for: album)
                    }
                }
            }
        }
    }
    
    /// 画面下部フッター
    private var multiSelectFooter: some View {
        HStack(spacing: 16) {
            Button("BUTTON_DESELECT", action: deselectAll)
                .foregroundColor(selectedAssetIDs.isEmpty ? .gray : .blue)
                .buttonStyle(.plain)
                .disabled(selectedAssetIDs.isEmpty)
            
            Spacer()
            
            Button("BUTTON_DELETE", action: deleteSelectedAssets)
                .foregroundColor(selectedAssetIDs.isEmpty ? .gray : .red)
                .buttonStyle(.plain)
                .disabled(selectedAssetIDs.isEmpty)
        }
        .padding(.horizontal)
        .padding(.top, 22)
        .padding(.bottom, 22)
        .background(Color("BackgroundColor"))
    }
    
    /// onAppear で呼び出す：写真ライブラリ権限のチェック
    private func checkPhotoLibraryPermission() {
        let current: PHAuthorizationStatus = if #available(iOS 14, *) {
            PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            PHPhotoLibrary.authorizationStatus()
        }
        authStatus = current
        
        switch current {
        case .notDetermined:
            requestPhotoLibraryAuth()
        case .authorized, .limited:
            viewModel.loadAssets(for: selectedAlbum)
        default:
            break
        }
    }
    
    /// 権限リクエスト処理
    private func requestPhotoLibraryAuth() {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    authStatus = status
                    if status == .authorized || status == .limited {
                        viewModel.loadAssets(for: selectedAlbum)
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    authStatus = status
                    if status == .authorized {
                        viewModel.loadAssets(for: selectedAlbum)
                    }
                }
            }
        }
    }
    
    // MARK: — PreferenceKey：セルのフレームを収集

    private struct AssetFrameKey: PreferenceKey {
        static var defaultValue: [String: CGRect] = [:]
        static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
            value.merge(nextValue(), uniquingKeysWith: { $1 })
        }
    }
    
    // MARK: — ナビゲーションアイコンのアクション
    
    /// アルバムアイコンタップ時
    private func onTappedAlbumIcon() {
        showingAlbumSelector = true
    }
    
    /// カメラアイコンタップ時
    private func onTappedCameraIcon() {
        showingImagePicker = true
    }
    
    /// 設定アイコンタップ時
    private func onTappedSettingIcon() {
        navigationPath.append(NavigationItem(id: .SETTING))
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GalleryView(navigationPath: .constant([]))
        }
    }
}
