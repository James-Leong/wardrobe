import Foundation

actor WeatherService {
    static let shared = WeatherService()

    struct LiveWeather: Codable {
        let province: String?
        let city: String?
        let adcode: String?
        let weather: String?
        let temperature: String?
        let winddirection: String?
        let windpower: String?
        let humidity: String?
        let reporttime: String?
        let temperature_float: String?
        let humidity_float: String?
    }

    struct WeatherResponse: Codable {
        let status: String?
        let info: String?
        let infocode: String?
        let count: String?
        let lives: [LiveWeather]?
    }

    enum WeatherError: Error {
        case missingAPIKey
        case networkError(String)
        case invalidResponse
        case apiError(String)
    }

    // Simple local cache stored in UserDefaults as JSON per city
    struct CachedWeather: Codable {
        let weather: LiveWeather
        let timestamp: Date
    }

    private func cacheKey(for city: String) -> String {
        return "WeatherCache_\(city)"
    }

    private func saveCache(_ cached: CachedWeather, for city: String) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(cached)
            UserDefaults.standard.set(data, forKey: cacheKey(for: city))
        } catch {
            // ignore cache write errors
        }
    }

    private func loadCache(for city: String) -> CachedWeather? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey(for: city)) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(CachedWeather.self, from: data)
        } catch {
            return nil
        }
    }

    /// Return cached weather if newer than maxAge, otherwise fetch and update cache.
    func getWeather(cityCode: String = "310115", maxAge: TimeInterval = 600) async throws -> (LiveWeather, Date) {
        if let cached = loadCache(for: cityCode) {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age <= maxAge {
                return (cached.weather, cached.timestamp)
            }
        }

        let fresh = try await fetchLiveWeather(cityCode: cityCode)
        let cached = CachedWeather(weather: fresh, timestamp: Date())
        saveCache(cached, for: cityCode)
        return (fresh, cached.timestamp)
    }

    func fetchLiveWeather(cityCode: String = "310115") async throws -> LiveWeather {
        // 从 Info.plist 读取 API Key（由 .xcconfig 注入）
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "AMAP_API_KEY") as? String,
              !apiKey.isEmpty else {
            throw WeatherError.missingAPIKey
        }

        var comps = URLComponents(string: "https://restapi.amap.com/v3/weather/weatherInfo")!
        comps.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "city", value: cityCode),
            URLQueryItem(name: "extensions", value: "base"),
            URLQueryItem(name: "output", value: "JSON")
        ]

        guard let url = comps.url else { throw WeatherError.invalidResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.networkError("HTTP error")
        }

        let decoder = JSONDecoder()
        let resp = try decoder.decode(WeatherResponse.self, from: data)
        if resp.status == "1", let first = resp.lives?.first {
            return first
        } else {
            let code = resp.infocode ?? ""
            throw WeatherError.apiError("\(resp.info ?? "Unknown API error") (infocode: \(code))")
        }
    }
}
