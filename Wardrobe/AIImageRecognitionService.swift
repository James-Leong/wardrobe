import Foundation

actor AIImageRecognitionService {
    static let shared = AIImageRecognitionService()

    struct RecognitionResult: Codable, Equatable {
        var color: String?
        var season: String?
        var occasion: String?
        var warmthLevel: Int?
        var laundryStatus: String?
        var note: String?
    }

    private struct VisionRuntimeConfig {
        let provider: String
        let token: String
        let model: String
        let apiURLString: String
        let useMock: Bool
    }

    enum ServiceError: LocalizedError {
        case missingAPIToken
        case invalidAPIURL
        case emptyResponse
        case responseDecodeFailed
        case apiError(String)
        case imageEncodeFailed

        var errorDescription: String? {
            switch self {
            case .missingAPIToken:
                return "缺少视觉模型 API Token，请先配置。"
            case .invalidAPIURL:
                return "视觉模型 API URL 配置无效。"
            case .emptyResponse:
                return "AI 返回为空。"
            case .responseDecodeFailed:
                return "无法解析 AI 返回内容。"
            case .apiError(let message):
                return "AI 接口失败：\(message)"
            case .imageEncodeFailed:
                return "图片编码失败。"
            }
        }
    }

    private struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: [ContentItem]
        }

        struct ContentItem: Encodable {
            let type: String
            let text: String?
            let image_url: ImageURL?
        }

        struct ImageURL: Encodable {
            let url: String
        }

        struct ResponseFormat: Encodable {
            let type: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
        let response_format: ResponseFormat
        let stream: Bool
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }

            let message: Message
        }

        let error: APIErrorPayload?
        let choices: [Choice]?
    }

    private struct APIErrorPayload: Decodable {
        let message: String?
    }

    func recognizeWardrobeInfo(from imageData: Data, mimeType: String = "image/jpeg") async throws -> RecognitionResult {
        let config = runtimeVisionConfig()

        if config.useMock || config.apiURLString.hasPrefix("mock://") {
            return mockResult()
        }

        guard !config.token.isEmpty else {
            throw ServiceError.missingAPIToken
        }

        guard let apiURL = URL(string: config.apiURLString) else {
            throw ServiceError.invalidAPIURL
        }

        let imageBase64 = imageData.base64EncodedString()
        guard !imageBase64.isEmpty else {
            throw ServiceError.imageEncodeFailed
        }

        let prompt = """
        你是服装识别助手。请识别图片中的一件衣物，并仅输出 JSON 对象，不要输出任何额外文本。
        字段：
        - color: 字符串，可空
        - season: 枚举之一[春, 夏, 秋, 冬, 四季]，可空
        - occasion: 枚举之一[通勤, 日常, 运动, 正式, 旅行, 居家]，可空
        - warmthLevel: 1-5 的整数，可空
        - laundryStatus: 枚举之一[干净可穿, 待清洗, 清洗中]，可空
        - note: 字符串，简短，最多 30 字，可空
        """

        let imageURLString = "data:\(mimeType);base64,\(imageBase64)"
        let requestBody = ChatRequest(
            model: config.model,
            messages: [
                .init(
                    role: "user",
                    content: [
                        .init(type: "image_url", text: nil, image_url: .init(url: imageURLString)),
                        .init(type: "text", text: prompt, image_url: nil)
                    ]
                )
            ],
            temperature: 0.1,
            response_format: .init(type: "json_object"),
            stream: false
        )

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.apiError("Invalid HTTP response")
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
            let message = (try? JSONDecoder().decode(ChatResponse.self, from: data).error?.message) ?? "HTTP \(httpResponse.statusCode)"
            throw ServiceError.apiError(message)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices?.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw ServiceError.emptyResponse
        }

        return try Self.parseRecognitionResult(from: content)
    }

    static func parseRecognitionResult(from raw: String) throws -> RecognitionResult {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonString = extractJSONObject(from: normalized) ?? normalized
        guard let data = jsonString.data(using: .utf8) else {
            throw ServiceError.responseDecodeFailed
        }

        do {
            let payload = try JSONDecoder().decode(RecognitionResult.self, from: data)
            return sanitize(payload)
        } catch {
            throw ServiceError.responseDecodeFailed
        }
    }

    static func mergeMissingFields(current: RecognitionResult, recognized: RecognitionResult) -> RecognitionResult {
        RecognitionResult(
            color: current.color ?? recognized.color,
            season: current.season ?? recognized.season,
            occasion: current.occasion ?? recognized.occasion,
            warmthLevel: current.warmthLevel ?? recognized.warmthLevel,
            laundryStatus: current.laundryStatus ?? recognized.laundryStatus,
            note: current.note ?? recognized.note
        )
    }

    private static func sanitize(_ result: RecognitionResult) -> RecognitionResult {
        let validSeasons = Set(["春", "夏", "秋", "冬", "四季"])
        let validOccasions = Set(["通勤", "日常", "运动", "正式", "旅行", "居家"])
        let validLaundryStatus = Set(["干净可穿", "待清洗", "清洗中"])

        let season = trimmedNonEmpty(result.season)
        let occasion = trimmedNonEmpty(result.occasion)
        let laundryStatus = trimmedNonEmpty(result.laundryStatus)
        let warmth = result.warmthLevel

        return RecognitionResult(
            color: trimmedNonEmpty(result.color),
            season: season.flatMap { validSeasons.contains($0) ? $0 : nil },
            occasion: occasion.flatMap { validOccasions.contains($0) ? $0 : nil },
            warmthLevel: {
                guard let warmth else { return nil }
                return (1...5).contains(warmth) ? warmth : nil
            }(),
            laundryStatus: laundryStatus.flatMap { validLaundryStatus.contains($0) ? $0 : nil },
            note: trimmedNonEmpty(result.note)
        )
    }

    private static func extractJSONObject(from raw: String) -> String? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") else {
            return nil
        }
        guard start <= end else { return nil }
        return String(raw[start...end])
    }

    private func mockResult() -> RecognitionResult {
        RecognitionResult(
            color: "米白",
            season: "春",
            occasion: "日常",
            warmthLevel: 2,
            laundryStatus: "干净可穿",
            note: "版型偏宽松"
        )
    }

    private func runtimeVisionConfig() -> VisionRuntimeConfig {
        let provider = (Self.infoValue(for: "AI_VISION_PROVIDER") ?? "bigmodel").lowercased()
        let providerDefaultModel: String
        let providerDefaultURL: String

        switch provider {
        case "bigmodel":
            providerDefaultModel = "glm-4.6v-flash"
            providerDefaultURL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
        default:
            providerDefaultModel = "vision-model"
            providerDefaultURL = "mock://vision"
        }

        let token = Self.infoValue(for: "AI_VISION_API_TOKEN")
            ?? Self.infoValue(for: "GLM_API_TOKEN")
            ?? ""
        let model = Self.infoValue(for: "AI_VISION_MODEL")
            ?? Self.infoValue(for: "GLM_MODEL")
            ?? providerDefaultModel
        let apiURLString = Self.infoValue(for: "AI_VISION_API_URL")
            ?? Self.infoValue(for: "GLM_API_URL")
            ?? providerDefaultURL

        let useMock = Self.infoBool(for: "AI_USE_MOCK")
            ?? Self.infoBool(for: "GLM_USE_MOCK")
            ?? apiURLString.hasPrefix("mock://")

        return VisionRuntimeConfig(
            provider: provider,
            token: token,
            model: model,
            apiURLString: apiURLString,
            useMock: useMock
        )
    }

    private static func infoValue(for key: String) -> String? {
        trimmedNonEmpty(Bundle.main.object(forInfoDictionaryKey: key) as? String)
    }

    private static func infoBool(for key: String) -> Bool? {
        guard let raw = infoValue(for: key)?.lowercased() else { return nil }
        switch raw {
        case "1", "true", "yes":
            return true
        case "0", "false", "no":
            return false
        default:
            return nil
        }
    }

    private static func trimmedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
