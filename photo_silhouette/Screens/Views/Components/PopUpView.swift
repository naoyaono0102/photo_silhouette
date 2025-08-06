//
//  PopUpView.swift
//  Pomodoro Timer
//
//  Created by 尾野順哉 on 2025/04/03.
//

import SwiftUI

struct DropdownTimePicker: View {
    // 秒単位の時間を保持（AppStorage などに置き換え可能）
    @Binding var time: Int
    // ドロップダウンが展開中かどうか
    @State private var isExpanded: Bool = false
    // ピッカーで一時的に選択している分・秒
    @State private var tempMinutes: Int = 0
    @State private var tempSeconds: Int = 0
    
    // 分と秒の選択範囲
    let minutesRange = Array(0...120)
    let secondsRange = Array(0...59)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // タップでドロップダウンを展開／閉じるボタン
            Button(action: {
                // 現在の値を一時変数にセット
                tempMinutes = time / 60
                tempSeconds = time % 60
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("\(time / 60):\(String(format: "%02d", time % 60))")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }
            
            // ドロップダウンの内容（展開中の場合のみ表示）
            if isExpanded {
                VStack(spacing: 0) {
                    // 2列のピッカー（左右に配置）
                    HStack {
                        Picker("", selection: $tempMinutes) {
                            ForEach(minutesRange, id: \.self) { minute in
                                Text("\(minute)")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                        
                        Picker("", selection: $tempSeconds) {
                            ForEach(secondsRange, id: \.self) { second in
                                Text("\(second)")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 150)
                    
                    Divider()
                    
                    HStack {
                        Button("キャンセル") {
                            withAnimation {
                                isExpanded = false
                            }
                        }
                        Spacer()
                        Button("OK") {
                            // 選択値を確定して更新
                            time = tempMinutes * 60 + tempSeconds
                            withAnimation {
                                isExpanded = false
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.systemBackground))
                )
                .shadow(radius: 4)
            }
        }
        .padding()
    }
}

struct DropdownTimePicker_Previews: PreviewProvider {
    @State static var time = 90
    static var previews: some View {
        DropdownTimePicker(time: $time)
            .previewLayout(.sizeThatFits)
    }
}
