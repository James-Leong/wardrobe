//
//  WardrobeGridView.swift
//  Wardrobe
//
//  Created by James Leong on 2026/3/7.
//

import SwiftUI
import PhotosUI
import SwiftData

struct WardrobeGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var showPhotosPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedCategory = "其他"
    @State private var showCategoryPicker = false
    
    // 自适应网格列数（根据屏幕宽度）
    @State private var gridColumns: [GridItem] = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // 计算网格列数
    private func calculateGridColumns() -> [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        let isCompact = horizontalSizeClass == .compact
        
        if isCompact {
            // 手机竖屏：2列，更大的间距
            return [
                GridItem(.flexible(minimum: 100), spacing: 12),
                GridItem(.flexible(minimum: 100), spacing: 12)
            ]
        } else {
            // 平板或横屏：根据屏幕宽度调整
            if screenWidth > 800 {
                return [GridItem](repeating: GridItem(.flexible(minimum: 120), spacing: 16), count: 4)
            } else {
                return [GridItem](repeating: GridItem(.flexible(minimum: 110), spacing: 14), count: 3)
            }
        }
    }
    
    var sortedItems: [Item] {
        items.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("我的衣橱")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(items.count) 件衣物")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // 仅当存在图片时显示筛选与上传按钮
                    if !items.isEmpty {
                        HStack(spacing: 12) {
                            // 分类筛选按钮
                            Button {
                                withAnimation(.spring()) {
                                    showCategoryPicker.toggle()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text(selectedCategory == "全部" ? "分类" : selectedCategory)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // 上传按钮
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onChange(of: selectedPhotoItem) { _, newValue in
                                if let newValue {
                                    handlePhotoSelection(newValue)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // 分隔线
                Divider()
                
                // 内容区域
                if items.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            ForEach(filteredItems, id: \.id) { item in
                                ModernImageCard(item: item)
                                    .aspectRatio(1, contentMode: .fit)
                                    .contextMenu {
                                        Button {
                                            // TODO: 编辑分类
                                        } label: {
                                            Label("编辑", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            deleteItem(item)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            
            // 加载状态
            if isLoading {
                loadingView
            }
            
            // 分类选择器
            if showCategoryPicker {
                categoryPickerView
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            gridColumns = calculateGridColumns()
        }
        .onChange(of: horizontalSizeClass) { _, _ in
            gridColumns = calculateGridColumns()
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 动画图标
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "photo.stack")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
            VStack(spacing: 12) {
                Text("开始建立你的数字衣橱")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("记录你的衣物，轻松管理每日穿搭")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // 引导按钮
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("添加第一件衣物")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .onChange(of: selectedPhotoItem) { _, newValue in
                    if let newValue {
                        handlePhotoSelection(newValue)
                    }
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("处理中...")
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Photo Selection Handler
    private func handlePhotoSelection(_ photoItem: PhotosPickerItem) {
        isLoading = true
        
        Task {
            do {
                guard let data = try await photoItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "无法加载图片"
                        showError = true
                    }
                    return
                }
                
                let fileName = try ImageManager.shared.saveImage(image)
                
                // Insert and save on MainActor so SwiftData Query updates correctly
                await MainActor.run {
                    do {
                        let newItem = Item(imagePath: fileName, category: selectedCategory)
                        modelContext.insert(newItem)
                        try modelContext.save()
                        isLoading = false
                        selectedPhotoItem = nil
                    } catch {
                        isLoading = false
                        errorMessage = "数据保存失败：\(error.localizedDescription)"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "图片处理失败：\(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Delete Handler
    private func deleteItem(_ item: Item) {
        do {
            try ImageManager.shared.deleteImage(fileName: item.imagePath)
            modelContext.delete(item)
            try modelContext.save()
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Category Picker View
    @ViewBuilder
    private var categoryPickerView: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        showCategoryPicker = false
                    }
                }
            
            VStack(spacing: 0) {
                Text("选择分类")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                Divider()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                                withAnimation(.spring()) {
                                    showCategoryPicker = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: categoryIcon(for: category))
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24)
                                    
                                    Text(category)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategory == category {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if category != categories.last {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                Divider()
                
                Button {
                    withAnimation(.spring()) {
                        showCategoryPicker = false
                    }
                } label: {
                    Text("取消")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .padding(.horizontal, 20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 5)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Helper Properties
    private var categories: [String] {
        ["全部", "上衣", "裤子", "鞋子", "外套", "配饰", "其他"]
    }
    
    private var filteredItems: [Item] {
        if selectedCategory == "全部" {
            return sortedItems
        }
        return sortedItems.filter { $0.category == selectedCategory }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "上衣": return "tshirt"
        case "裤子": return "figure.walk"
        case "鞋子": return "shoe"
        case "外套": return "jacket"
        case "配饰": return "bag"
        case "全部": return "square.grid.2x2"
        default: return "tag"
        }
    }
}

// MARK: - Modern Image Card Component
struct ModernImageCard: View {
    let item: Item
    @State private var image: UIImage?
    @State private var isPressed = false
    @State private var showCategory = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGray6),
                    Color(.systemGray5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // 图片内容
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .black.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("加载中...")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // 底部信息栏
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: categoryIcon)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    
                    Text(item.category)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
                .opacity(showCategory ? 1 : 0)
                
                Spacer()
                
                // 时间标签
                Text(timeAgo)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(8)
        }
        .aspectRatio(1, contentMode: .fill)
        .cornerRadius(16)
        .shadow(
            color: Color.black.opacity(isPressed ? 0.2 : 0.1),
            radius: isPressed ? 8 : 4,
            x: 0,
            y: isPressed ? 4 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            loadImage()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCategory.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0.1) {
            // 长按效果
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.loadImage(fileName: item.imagePath)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
    
    private var categoryIcon: String {
        switch item.category {
        case "上衣": return "tshirt"
        case "裤子": return "figure.walk"
        case "鞋子": return "shoe"
        case "外套": return "jacket"
        case "配饰": return "bag"
        default: return "tag"
        }
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
}

#Preview {
    WardrobeGridView()
        .modelContainer(for: Item.self, inMemory: true)
}
