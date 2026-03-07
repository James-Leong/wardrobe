//
//  WardrobeGridView_Preview.swift
//  Wardrobe
//
//  Created by James Leong on 2026/3/7.
//

import SwiftUI
import SwiftData

struct WardrobeGridView_Preview: View {
    @State private var mockItems: [Item] = []
    
    var body: some View {
        VStack(spacing: 0) {
            Text("网格布局测试预览")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("1. 空状态测试")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    WardrobeGridView()
                        .frame(height: 400)
                        .modelContainer(for: Item.self, inMemory: true)
                    
                    Divider()
                    
                    Text("2. 多图测试 (6张图片)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    WardrobeGridView()
                        .frame(height: 600)
                        .modelContainer(createMockContainer())
                }
                .padding()
            }
        }
    }
    
    private func createMockContainer() -> ModelContainer {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // 添加模拟数据
            let mockItems = [
                Item(imagePath: "mock1", category: "上衣"),
                Item(imagePath: "mock2", category: "裤子"),
                Item(imagePath: "mock3", category: "鞋子"),
                Item(imagePath: "mock4", category: "外套"),
                Item(imagePath: "mock5", category: "配饰"),
                Item(imagePath: "mock6", category: "其他")
            ]
            
            for item in mockItems {
                container.mainContext.insert(item)
            }
            
            try container.mainContext.save()
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

#Preview {
    WardrobeGridView_Preview()
}