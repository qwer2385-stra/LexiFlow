import SwiftUI
import CoreData

/// 输出（写作）页面
struct OutputView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = OutputViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserMO.createdAt, ascending: true)],
        animation: .default
    ) private var users: FetchedResults<UserMO>

    private var currentUser: UserMO? { users.first }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 写作提示
                    promptSection

                    // 输入区
                    inputSection

                    // 反馈
                    if let feedback = viewModel.feedback {
                        feedbackSection(feedback)
                    }

                    // 提交按钮
                    submitButton
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("英文输出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清除") {
                        viewModel.clear()
                    }
                    .disabled(viewModel.userInput.isEmpty)
                }
            }
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.warningOrange)
                Text("写作提示")
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)
            }

            Text(viewModel.writingPrompt)
                .font(.callout)
                .foregroundColor(.textSecondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.warningOrange.opacity(0.06))
                )
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pencil.line")
                    .foregroundColor(.accentBlue)
                Text("你的写作")
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)

                Spacer()

                // 字数统计
                Text("\(viewModel.wordCount) 词")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondaryBackground)
                    .clipShape(Capsule())
            }

            TextEditor(text: $viewModel.userInput)
                .font(.lfBody)
                .frame(minHeight: 200)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondaryBackground, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.userInput.isEmpty {
                        Text("Start writing in English...")
                            .font(.lfBody)
                            .foregroundColor(.textSecondary.opacity(0.6))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: viewModel.userInput) { _ in
                    viewModel.updateWordCount()
                }
        }
    }

    // MARK: - Feedback

    private func feedbackSection(_ feedback: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.successGreen)
            Text(feedback)
                .font(.callout)
                .foregroundColor(.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.successGreen.opacity(0.08))
        )
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            guard let user = currentUser else { return }
            let progressRequest = DailyProgressMO.fetchRequest()
            progressRequest.predicate = NSPredicate(format: "date == %@", Date().startOfDay as NSDate)
            progressRequest.fetchLimit = 1
            let todayProgress = try? viewContext.fetch(progressRequest).first
            viewModel.submit(context: viewContext, user: user, todayProgress: todayProgress)
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("提交写作")
            }
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.userInput.isBlank ? Color.textSecondary : Color.accentBlue)
            )
        }
        .disabled(viewModel.userInput.isBlank || viewModel.isSubmitting)
    }
}

// MARK: - Preview

#Preview {
    OutputView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
