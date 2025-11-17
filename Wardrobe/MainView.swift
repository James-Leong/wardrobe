import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem {
                    Image(systemName: "rectangle.grid.2x2")
                    Text("衣橱")
                }

            OutfitView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("搭配")
                }

            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
        }
    }
}

// MARK: - Placeholder Views
struct WardrobeView: View {
    var body: some View {
        NavigationView {
            Text("衣橱 网格视图 - 占位")
                .navigationTitle("衣橱")
        }
    }
}

struct CalendarView: View {
    var body: some View {
        NavigationView {
            Text("日历 - 占位")
                .navigationTitle("日历")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("设置 - 占位")
                .navigationTitle("设置")
        }
    }
}

// MARK: - Previews
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .preferredColorScheme(.light)

        MainView()
            .preferredColorScheme(.dark)
    }
}
