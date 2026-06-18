import SwiftUI

/// 主路由 — TabView 5 个 Tab
struct ContentView: View {

    // MARK: - State

    @State private var selectedTab: Tab = .home

    // MARK: - Tab 枚举

    enum Tab: String, CaseIterable {
        case home = "首页"
        case wordBook = "单词本"
        case review = "复习"
        case stats = "统计"
        case profile = "我的"

        var icon: String {
            switch self {
            case .home:     return "house.fill"
            case .wordBook: return "book.fill"
            case .review:   return "arrow.triangle.2.circlepath"
            case .stats:    return "chart.bar.fill"
            case .profile:  return "person.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            WordBookView()
                .tabItem {
                    Label(Tab.wordBook.rawValue, systemImage: Tab.wordBook.icon)
                }
                .tag(Tab.wordBook)

            ReviewView()
                .tabItem {
                    Label(Tab.review.rawValue, systemImage: Tab.review.icon)
                }
                .tag(Tab.review)

            StatsView()
                .tabItem {
                    Label(Tab.stats.rawValue, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(.accentBlue)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
