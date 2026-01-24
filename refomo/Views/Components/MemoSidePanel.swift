//
//  MemoSidePanel.swift
//  refomo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MemoSidePanel: View {
    @Binding var memo: String
    @Binding var isVisible: Bool
    let onClose: () -> Void

    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .body) private var padding: CGFloat = 16
    @ScaledMetric(relativeTo: .footnote) private var hintFontSize: CGFloat = 12

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with close hint
            Text("→ 스와이프하여 닫기")
                .font(.system(size: hintFontSize))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            // TextEditor
            ZStack(alignment: .topLeading) {
                if memo.isEmpty {
                    Text("타이머 실행 중 메모를 작성할 수 있습니다")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $memo)
                    .focused($isTextEditorFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)

            // Character count
            if !memo.isEmpty {
                HStack {
                    Spacer()
                    Text("\(memo.count) / 500")
                        .font(.caption2)
                        .foregroundColor(memo.count > 500 ? .red : .secondary)
                }
            }
        }
        .padding(padding)
        .frame(maxHeight: .infinity)
        .background(Color(.tertiarySystemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("메모 패널")
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                // Delay to allow panel animation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextEditorFocused = true
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var memo = ""
        @State private var isVisible = true

        var body: some View {
            MemoSidePanel(
                memo: $memo,
                isVisible: $isVisible,
                onClose: { print("Close memo panel") }
            )
            .frame(width: 300, height: 600)
        }
    }

    return PreviewWrapper()
}
