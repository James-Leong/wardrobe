import SwiftUI

struct OutfitView: View {
    @State private var recommendations: [Recommendation] = Recommendation.sample
    @State private var weather: WeatherService.LiveWeather? = nil
    @State private var lastUpdated: Date? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let w = weather {
                        WeatherCardView(temperature: Int(w.temperature ?? "0") ?? 0, condition: w.weather ?? "—", lastUpdated: lastUpdated)
                    } else if weather == nil && lastUpdated == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.thinMaterial)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        WeatherCardView(temperature: 22, condition: "多云", lastUpdated: lastUpdated)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("今日推荐搭配")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button("编辑") {
                                // TODO: 编辑动作
                            }
                            .font(.subheadline)
                        }

                        ForEach($recommendations) { $rec in
                            RecommendationRow(rec: $rec)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("搭配")
            .task {
                await loadWeather()
            }
        }
    }

    func loadWeather() async {
        do {
            let (w, timestamp) = try await WeatherService.shared.getWeather(cityCode: "310115", maxAge: 600)
            await MainActor.run {
                self.weather = w
                self.lastUpdated = timestamp
            }
        } catch {
            // Keep existing weather/lastUpdated if present; no loading state
        }
    }
}

// MARK: - Recommendation Models & Views
struct Recommendation: Identifiable {
    var id = UUID()
    var title: String
    var items: [String] // simple representation, e.g., names or asset ids
    var note: String?

    static let sample: [Recommendation] = [
        Recommendation(title: "周末休闲", items: ["白色T恤", "牛仔裤", "白鞋"], note: "舒适居家/出街"),
        Recommendation(title: "商务休闲", items: ["蓝色衬衫", "卡其裤", "深色皮鞋"], note: "适合会议/午餐"),
        Recommendation(title: "晚间外出", items: ["黑色连衣裙", "高跟鞋", "亮色包"], note: "约会/聚会首选")
    ]
}

struct RecommendationRow: View {
    @Binding var rec: Recommendation

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(rec.title)
                    .font(.headline)
                Text(rec.note ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(rec.items.prefix(3), id: \ .self) { name in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 64)
                        .overlay(Text(name.prefix(1)).font(.caption))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.001))
        .cornerRadius(10)
    }
}

// MARK: - Weather Card
struct WeatherCardView: View {
    var temperature: Int
    var condition: String
    var lastUpdated: Date?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading) {
                    Text("当前天气")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(temperature)°")
                            .font(.largeTitle)
                            .bold()
                        Text(condition)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            if let date = lastUpdated {
                Text(formattedMinute(date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(6)
                    .offset(x: -6, y: 6)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func formattedMinute(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return "更新：\(fmt.string(from: d))"
    }
}

// MARK: - Previews
struct OutfitView_Previews: PreviewProvider {
    static var previews: some View {
        OutfitView()
            .previewDevice("iPhone 14")
        OutfitView()
            .previewDevice("iPhone SE (2nd generation)")
    }
}
