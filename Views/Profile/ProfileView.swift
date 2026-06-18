import SwiftUI
import CoreData

/// 个人设置页面
struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @StateObject private var viewModel = ProfileViewModel()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserMO.createdAt, ascending: true)],
        animation: .default
    ) private var users: FetchedResults<UserMO>

    @State private var showClearAlert = false

    private var currentUser: UserMO? { users.first }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 头像 + 昵称
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentBlue.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Text(String(viewModel.nickname.prefix(1)))
                                .font(.title.bold())
                                .foregroundColor(.accentBlue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            TextField("昵称", text: $viewModel.nickname)
                                .font(.title3.bold())

                            Text("词汇量: \(viewModel.totalWords) | 已掌握: \(viewModel.masteredWords)")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 学习目标设置
                Section("学习目标") {
                    HStack {
                        Text("每日时长")
                        Spacer()
                        Picker("", selection: $viewModel.targetDailyMinutes) {
                            Text("15 分钟").tag(15)
                            Text("30 分钟").tag(30)
                            Text("45 分钟").tag(45)
                            Text("60 分钟").tag(60)
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("每周单词")
                        Spacer()
                        Picker("", selection: $viewModel.targetWeeklyWords) {
                            Text("30 词").tag(30)
                            Text("50 词").tag(50)
                            Text("70 词").tag(70)
                            Text("100 词").tag(100)
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("CET 等级")
                        Spacer()
                        Picker("", selection: $viewModel.cetLevel) {
                            Text("CET4").tag("CET4")
                            Text("CET6").tag("CET6")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                }

                // 提醒设置
                Section("学习提醒") {
                    Toggle("每日提醒", isOn: $viewModel.reminderEnabled)
                        .onChange(of: viewModel.reminderEnabled) { _ in
                            viewModel.toggleReminder()
                        }

                    if viewModel.reminderEnabled {
                        DatePicker(
                            "提醒时间",
                            selection: Binding(
                                get: {
                                    Calendar.current.date(
                                        from: DateComponents(
                                            hour: viewModel.reminderHour,
                                            minute: viewModel.reminderMinute
                                        )
                                    ) ?? Date()
                                },
                                set: { date in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    viewModel.reminderHour = components.hour ?? 9
                                    viewModel.reminderMinute = components.minute ?? 0
                                    viewModel.updateReminderTime()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // 数据管理
                Section("数据管理") {
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除所有学习进度")
                        }
                    }
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        viewModel.saveProfile(context: viewContext, user: currentUser)
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel.loadProfile(context: viewContext, user: currentUser)
            }
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    viewModel.clearAllProgress(context: viewContext, user: currentUser)
                }
            } message: {
                Text("此操作将清除所有学习进度和单词本数据，不可恢复。")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
