//
//  Item.swift
//  Wardrobe
//
//  Created by James Leong on 2025/11/18.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID = UUID()
    var imagePath: String  // 本地文件系统路径
    var timestamp: Date
    var category: String = "其他"  // 衣服、裤子、鞋等分类
    var color: String?
    var season: String?
    var occasion: String?
    var warmthLevel: Int?
    var laundryStatus: String?
    var note: String?
    
    init(
        imagePath: String,
        timestamp: Date = Date(),
        category: String = "其他",
        color: String? = nil,
        season: String? = nil,
        occasion: String? = nil,
        warmthLevel: Int? = nil,
        laundryStatus: String? = nil,
        note: String? = nil
    ) {
        self.imagePath = imagePath
        self.timestamp = timestamp
        self.category = category
        self.color = color
        self.season = season
        self.occasion = occasion
        self.warmthLevel = warmthLevel
        self.laundryStatus = laundryStatus
        self.note = note
    }
}
