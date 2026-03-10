import Testing
@testable import Wardrobe

struct AIImageRecognitionServiceTests {

    @Test
    func parseRecognitionResult_acceptsWrappedJSONContent() throws {
        let raw = """
        这是识别结果：
        {
          "color": "黑色",
          "season": "秋",
          "occasion": "通勤",
          "warmthLevel": 3,
          "laundryStatus": "干净可穿",
          "note": "面料偏挺括"
        }
        """

        let parsed = try AIImageRecognitionService.parseRecognitionResult(from: raw)
        #expect(parsed.color == "黑色")
        #expect(parsed.season == "秋")
        #expect(parsed.occasion == "通勤")
        #expect(parsed.warmthLevel == 3)
        #expect(parsed.laundryStatus == "干净可穿")
        #expect(parsed.note == "面料偏挺括")
    }

    @Test
    func parseRecognitionResult_filtersInvalidValues() throws {
        let raw = """
        {
          "color": "  白色  ",
          "season": "雨季",
          "occasion": "开会",
          "warmthLevel": 8,
          "laundryStatus": "未知",
          "note": "  "
        }
        """

        let parsed = try AIImageRecognitionService.parseRecognitionResult(from: raw)
        #expect(parsed.color == "白色")
        #expect(parsed.season == nil)
        #expect(parsed.occasion == nil)
        #expect(parsed.warmthLevel == nil)
        #expect(parsed.laundryStatus == nil)
        #expect(parsed.note == nil)
    }

    @Test
    func mergeMissingFields_onlyFillsEmptyValues() {
        let current = AIImageRecognitionService.RecognitionResult(
            color: "藏青",
            season: nil,
            occasion: "通勤",
            warmthLevel: nil,
            laundryStatus: nil,
            note: nil
        )
        let recognized = AIImageRecognitionService.RecognitionResult(
            color: "黑色",
            season: "秋",
            occasion: "日常",
            warmthLevel: 3,
            laundryStatus: "干净可穿",
            note: "版型偏修身"
        )

        let merged = AIImageRecognitionService.mergeMissingFields(current: current, recognized: recognized)
        #expect(merged.color == "藏青")
        #expect(merged.season == "秋")
        #expect(merged.occasion == "通勤")
        #expect(merged.warmthLevel == 3)
        #expect(merged.laundryStatus == "干净可穿")
        #expect(merged.note == "版型偏修身")
    }
}
