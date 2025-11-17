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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
