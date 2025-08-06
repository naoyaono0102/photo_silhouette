//
//  DateToggleControlsView.swift
//  white_frame
//
//  Created by 尾野順哉 on 2025/07/10.
//

import SwiftUI

// MARK: - 日付トグルコントロール

struct DateToggleControlsView: View {
    @Binding var selectedDate: Date
    @Binding var isVisible: Bool
    @Binding var selectedColor: Color

    @State private var showCalendar: Bool = false
    @State private var showCustomPicker: Bool = false
    @State private var customColor: Color = .orange

    private let simpleColors: [Color] = [
        .white, .black,
        .orange, .red, .yellow, .green, .blue, .purple, .pink, .gray
    ]
    private let itemSize: CGFloat = 28

    var body: some View {
        VStack {
            // 日付 + トグル行
            ZStack {
                HStack(spacing: 16) {
                    // 日付表示
                    Text(selectedDate, style: .date)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary))
                        .onTapGesture {
                            withAnimation { showCalendar.toggle() }
                        }
                        .overlay {
                            if showCalendar {
                                // ポップアップカレンダー
                                VStack {
                                    DatePicker(
                                        "", selection: $selectedDate,
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .padding(16) // カレンダー内部の余白追加
                                    .onChange(of: selectedDate) { _ in
                                        // 日付選択後に自動で閉じる
                                        withAnimation { showCalendar = false }
                                    }
                                }
                                .frame(width: 300, height: 340)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
                                .offset(x: 80, y: -200)
                            }
                        }
                        .zIndex(showCalendar ? 1 : 0)
                    Spacer()

                    // 表示トグル
                    HStack(spacing: 8) {
                        Text("EDIT_DATE_DISPLAY")
                        Toggle("", isOn: $isVisible)
                            .labelsHidden()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color("MainAccentColor")))
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)

            // カラー選択行
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(simpleColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: itemSize, height: itemSize)
                            .overlay(
                                Circle().stroke(
                                    color == selectedColor ? Color.accentColor : .clear,
                                    lineWidth: 3
                                )
                            )
                            .onTapGesture { selectedColor = color }
                    }
                    // カスタムカラー追加
                    ColorPicker("", selection: $customColor)
                        .labelsHidden()
                        .frame(width: itemSize, height: itemSize)
                        .clipShape(Circle())
                        .onChange(of: customColor) { new in
                            selectedColor = new
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .overlay {
            if showCalendar {
                // 背景タップで閉じる
                Color.black.opacity(0.00001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showCalendar = false }
                    }
                    .zIndex(0)
            }
        }
    }
}
