import SwiftUI

/// 搜索栏组件
/// TextField + 清除按钮 + 搜索图标
struct SearchBar: View {

    /// 搜索文本绑定
    @Binding var text: String
    /// 占位文字
    var placeholder: String = "搜索单词..."
    /// 搜索回调
    var onSubmit: (() -> Void)?

    // MARK: - Focus

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: 10) {
            // 搜索图标
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
                .font(.system(size: 16))

            // 输入框
            TextField(placeholder, text: $text)
                .font(.lfBody)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
                .submitLabel(.search)

            // 清除按钮（有文字时显示）
            if !text.isEmpty {
                Button {
                    text = ""
                    onSubmit?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondaryBackground)
        )
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SearchBar(text: .constant(""), placeholder: "搜索单词...")
        SearchBar(text: .constant("abandon"), placeholder: "搜索单词...")
    }
    .padding()
    .background(Color.white)
}
