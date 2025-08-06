//
//  InitialView.swift
//  ToDoList
//
//  Created by 尾野順哉 on 2025/03/21.
//

import Combine
import SwiftData
import SwiftUI

struct TabManagerView: View {
    // TABテーブルとのバインディング

    // 降順
//    @Query(sort: \ToDoTab.order, order: .reverse) private var toDoTabList: [ToDoTab]

    // 昇順
    @Query(sort: \ToDoTab.order, order: .forward) private var toDoTabList: [ToDoTab]

//    @State private var isAddTatbPresented: Bool = false
//    @State private var isEditTabPresented: Bool = false
    @State private var alertInfo: AlertInfo?
    @State private var selectedToDoTab: ToDoTab?

    // 前回のタブ数を保持する変数
    @State private var previousTabCount: Int = 0

    @Binding var showAddSheet: Bool
    @Binding var showEditSheet: Bool

    // キーボード高さを保持する状態変数
    @State private var keyboardHeight: CGFloat = 0

    private let todoTabService = ToDoTabService()

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in

                if toDoTabList.isEmpty {
                    return AnyView(
                        Text("NO_TABS")
                            .foregroundStyle(.gray)
                    )
                }
                else {
                    return AnyView(
                        CustomList(
                            items: toDoTabList,
                            rowContent: { tab in
                                Text(tab.name)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    //                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                    //                        .background(.red)
                                    .contentShape(Rectangle()) // タップ領域を確保,背景色なしでもタップできるように
                                    .onTapGesture {
                                        selectedToDoTab = tab
                                        showEditSheet = true
                                        //                            isEditTabPresented = true
                                    }
                            },
                            onDelete: onDeleteButtonTapped,
                            onMove: onMove
                        )
                        // List に対してキーボードの自動調整を無効にする
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                        .contentMargins(.bottom, 20)
                        //                // ① シート表示時のスクロール（新規追加モード）
                        //                .onChange(of: showAddSheet) { isShowing, _ in
                        //                    if isShowing, let lastTab = toDoTabList.last {
                        //                        print("スクロールターゲット：\(lastTab.name)")
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        //                            withAnimation {
                        //                                proxy.scrollTo(lastTab.id, anchor: .top)
                        //                            }
                        //                        }
                        //                    }
                        //                }
                        //                // ② シート表示時のスクロール（編集モード）
                        //                .onChange(of: showEditSheet) { isShowing, _ in
                        //                    if isShowing, let id = selectedToDoTab?.id {
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        //                            withAnimation {
                        //                                proxy.scrollTo(id, anchor: .center)
                        //                            }
                        //                        }
                        //                    }
                        //                }
                        //                // ③ タブの登録時のスクロール
                        //                .onChange(of: toDoTabList.count) { newCount, oldCount in
                        //                    print("タブの数が変わったので呼ばれた: \(newCount) (前回: \(oldCount))")
                        //                    // 新しくタブが追加された場合のみスクロール
                        //                    if newCount > oldCount, let lastTab = toDoTabList.last {
                        //                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        //                            withAnimation {
                        //                                proxy.scrollTo(lastTab.id, anchor: .top)
                        //                            }
                        //                        }
                        //                    }
                        //                }

                        // ① シート表示時のスクロール（新規追加モード）
                        .onChange(of: showAddSheet) { isShowing in
                            if isShowing, let lastTab = toDoTabList.last {
                                print("スクロールターゲット：\(lastTab.name)")

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo(lastTab.id, anchor: .top)
                                    }
                                }
                            }
                        }
                        // ② シート表示時のスクロール（編集モード）
                        .onChange(of: showEditSheet) { isShowing in
                            if isShowing, let id = selectedToDoTab?.id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo(id, anchor: .center)
                                    }
                                }
                            }
                        }
                        // ③ タブの登録時のスクロール
                        .onChange(of: toDoTabList.count) { newCount in
                            print("タブの数が変わったので呼ばれた: \(newCount) (前回: \(previousTabCount))")
                            // 新しくタブが追加された場合のみスクロール
                            if newCount > previousTabCount, let lastTab = toDoTabList.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo(lastTab.id, anchor: .top)
                                    }
                                }
                            }
                            previousTabCount = newCount
                        }
                        .onAppear {
                            // 初回表示時にタブ数をセット
                            previousTabCount = toDoTabList.count
                        }
                    )
                }
            }
        }
        // 新規登録シート
        .inputSheet(
            showSheet: $showAddSheet,
            defaultText: "",
            isEditMode: false,
            placeholder: "TAB_INPUT_FIELD_PLACEHOLDER",
            action: addTab
        )
        // 編集登録シート
        .inputSheet(
            showSheet: $showEditSheet,
            defaultText: selectedToDoTab?.name ?? "",
            isEditMode: true,
            placeholder: "TAB_INPUT_FIELD_PLACEHOLDER",
            action: editTab
        )
        // ナビゲーション設定
        .navigationBarSetting(title: "TAB_PAGE_NAME", isVisible: true)
        .navigationBarIconSetting(name: "plus", isEnabled: true, iconPosition: .trailing, action: onTapAddIconTapped)
        // 画面スタイル
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor"))

        // コンポーネント
//        .textFieldAlert(
//            isPresented: $isAddTatbPresented,
//            title: "タブ追加",
//            message: "タブ名を入力してください",
//            placeHolder: "例）勉強",
//            defaultText: "",
//            maxLength: 20,
//            onConfirm: addTab
//        )
//        .textFieldAlert(
//            isPresented: $isEditTabPresented,
//            title: "タブ編集",
//            message: "修正するタブ名を入力してください",
//            placeHolder: "例）勉強",
//            defaultText: selectedToDoTab?.name ?? "",
//            maxLength: 20,
//            onConfirm: editTab
//        )
        .customAlert(alertInfo: $alertInfo)
    }

    // タスクの並び替え
    private func onMove(from: IndexSet, to: Int) {
        print("== タブの移動処理開始 ==")
        print("from: \(from)")
        print("to: \(to)")

        // 並び替え
        // @Query で取得した toDoTabList は読み取り専用なので、mutable な配列に変換
        var mutableTabs = Array(toDoTabList)
        mutableTabs.move(fromOffsets: from, toOffset: to)
        print("並び替え後のタブ一覧: \(mutableTabs.map { $0.name })")

        // DB更新：サービス側でタブの order を更新する
        do {
            try todoTabService.updateTabOrder(tabs: mutableTabs)
        } catch {
            print("タブの並び替え保存エラー: \(error.localizedDescription)")
            alertInfo = AlertInfo(title: "エラー", message: "タブの並び替えの保存に失敗しました。")
        }
    }

    // +ボタンタップ時の処理
    private func onTapAddIconTapped() {
        print("+ボタンがタップされました")
        showAddSheet = true
//        isAddTatbPresented = true
    }

    // タブの追加
    private func addTab(text: String) {
        print("タブの追加：\(text)")
        do {
            // 戻り値が不要な場合は _= とする
            _ = try todoTabService.addTab(name: text)
        } catch {
            print("タブの追加処理でエラーが発生しました")
            alertInfo = .init(
                title: "ALERT_ERROR",
                message: "ALERT_TAB_ADD_FAILURE"
            )
        }
    }

    // タブの編集
    private func editTab(text: String) {
        guard let toDoTasks = selectedToDoTab else {
            return
        }

        do {
            try todoTabService.editTab(tabId: toDoTasks.id, name: text)

        } catch {
            print("タブの変更処理でエラーが発生しました")
            alertInfo = .init(
                title: "ALERT_ERROR",
                message: "ALERT_TAB_EDIT_FAILURE"
            )
        }
    }

    // タブの削除ボタンをタップ時
    private func onDeleteButtonTapped(tab: ToDoTab) {
        do {
            try todoTabService.deleteTab(tabId: tab.id)

        } catch {
            print("タブの削除処理でエラーが発生しました")
            alertInfo = .init(
                title: "ALERT_ERROR",
                message: "ALERT_TAB_DELETION_FAILURE"
            )
        }
    }
}

#Preview {
    @Previewable @State var showEditSheet = false
    @Previewable @State var showAddSheet = false

    NavigationView {
        TabManagerView(
            showAddSheet: $showAddSheet,
            showEditSheet: $showEditSheet
        )
        .modelContainer(SwiftDataService.shared.getModelContainer())
    }
}
