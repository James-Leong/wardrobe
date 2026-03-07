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
    
    init(imagePath: String, timestamp: Date = Date(), category: String = "其他") {
        self.imagePath = imagePath
        self.timestamp = timestamp
        self.category = category
    }
}
