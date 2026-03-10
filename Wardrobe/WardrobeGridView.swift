//
//  WardrobeGridView.swift
//  Wardrobe
//
//  Created by James Leong on 2026/3/7.
//

import SwiftUI
import PhotosUI
import SwiftData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private let wardrobeCategories = ["全部", "上衣", "裤子", "鞋子", "外套", "配饰", "其他"]
private let editableWardrobeCategories = Array(wardrobeCategories.dropFirst())
private let wardrobeAllCategory = "全部"
private let wardrobeFallbackCategory = "其他"

private func wardrobeCategoryIcon(for category: String) -> String {
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

private extension Color {
    static var wardrobeBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        return Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var wardrobeCardBaseLight: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray6)
        #elseif canImport(AppKit)
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var wardrobeCardBaseDark: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGray5)
        #elseif canImport(AppKit)
        return Color(nsColor: .underPageBackgroundColor)
        #endif
    }
}

struct WardrobeGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var items: [Item]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedFilter = wardrobeAllCategory
    @State private var showCategoryPicker = false
    @State private var editingItem: Item?
    @State private var viewingItem: Item?
    @State private var gridColumns: [GridItem] = []

    private var sortedItems: [Item] {
        items.sorted { $0.timestamp > $1.timestamp }
    }

    private var filteredItems: [Item] {
        if selectedFilter == wardrobeAllCategory {
            return sortedItems
        }

        return sortedItems.filter { $0.category == selectedFilter }
    }

    private var inventorySubtitle: String {
        if selectedFilter == wardrobeAllCategory {
            return "\(items.count) 件衣物"
        }

        return "\(filteredItems.count) / \(items.count) 件衣物"
    }

    private func calculateGridColumns() -> [GridItem] {
        #if os(iOS) || os(tvOS)
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.screen.bounds.width }
            .max() ?? 390
        #elseif os(macOS)
        let screenWidth: CGFloat = 800
        #endif

        let isCompact = horizontalSizeClass == .compact

        if isCompact {
            // 手机竖屏：2列，更大的间距
            return [
                GridItem(.flexible(minimum: 100), spacing: 14),
                GridItem(.flexible(minimum: 100), spacing: 14)
            ]
        }

        if screenWidth > 800 {
            // 平板或横屏：根据屏幕宽度调整
            return [GridItem](repeating: GridItem(.flexible(minimum: 120), spacing: 18), count: 4)
        }

        return [GridItem](repeating: GridItem(.flexible(minimum: 110), spacing: 16), count: 3)
    }

    var body: some View {
        ZStack {
            Color.wardrobeBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                Divider()

                if items.isEmpty {
                    emptyStateView
                } else if filteredItems.isEmpty {
                    filteredEmptyStateView
                } else {
                    gridView
                }
            }

            if isLoading {
                loadingView
            }

            if showCategoryPicker {
                categoryPickerView
            }
        }
        .sheet(item: $editingItem, onDismiss: {
            editingItem = nil
        }) { item in
            editCategorySheet(for: item)
        }
        .fullScreenCover(item: $viewingItem, onDismiss: {
            viewingItem = nil
        }) { item in
            NavigationStack {
                WardrobeItemDetailView(item: item)
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

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("我的衣橱")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text(inventorySubtitle)
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
                            Text(selectedFilter == wardrobeAllCategory ? "分类" : selectedFilter)
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

                    uploadButton
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var uploadButton: some View {
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

    private var gridView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(filteredItems, id: \.id) { item in
                    ModernImageCard(item: item, onTap: {
                        viewingItem = item
                    })
                        .aspectRatio(1, contentMode: .fit)
                        .contextMenu {
                            Button {
                                editingItem = item
                            } label: {
                                Label("编辑分类", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                deleteItem(item)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 34)
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

    private var filteredEmptyStateView: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("没有符合“\(selectedFilter)”的衣物")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("可以切换筛选条件，或直接继续上传新图片。")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("查看全部") {
                withAnimation(.spring()) {
                    selectedFilter = wardrobeAllCategory
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(.horizontal, 24)
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
            .background(Color.wardrobeBackground)
            .cornerRadius(12)
        }
    }

    // MARK: - Photo Selection Handler
    private func handlePhotoSelection(_ photoItem: PhotosPickerItem) {
        let newItemCategory = selectedFilter == wardrobeAllCategory ? wardrobeFallbackCategory : selectedFilter

        isLoading = true

        Task {
            do {
                guard let data = try await photoItem.loadTransferable(type: Data.self) else {
                    await MainActor.run {
                        presentPhotoError("无法加载图片")
                    }
                    return
                }

                #if canImport(UIKit)
                guard let image = UIImage(data: data) else {
                    await MainActor.run {
                        presentPhotoError("无法解析图片")
                    }
                    return
                }
                #elseif canImport(AppKit)
                guard let image = NSImage(data: data) else {
                    await MainActor.run {
                        presentPhotoError("无法解析图片")
                    }
                    return
                }
                #endif

                let fileName = try ImageManager.shared.saveImage(image)

                // Insert and save on MainActor so SwiftData Query updates correctly
                await MainActor.run {
                    do {
                        let newItem = Item(imagePath: fileName, category: newItemCategory)
                        modelContext.insert(newItem)
                        try modelContext.save()
                        isLoading = false
                        selectedPhotoItem = nil
                    } catch {
                        isLoading = false
                        selectedPhotoItem = nil
                        errorMessage = "数据保存失败：\(error.localizedDescription)"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    presentPhotoError("图片处理失败：\(error.localizedDescription)")
                }
            }
        }
    }

    private func presentPhotoError(_ message: String) {
        isLoading = false
        selectedPhotoItem = nil
        errorMessage = message
        showError = true
    }

    // MARK: - Delete Handler
    private func deleteItem(_ item: Item) {
        do {
            try ImageManager.shared.deleteImage(fileName: item.imagePath)
            modelContext.delete(item)
            try modelContext.save()

            if editingItem?.id == item.id {
                editingItem = nil
            }
        } catch {
            errorMessage = "删除失败：\(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Edit Category Handler
    private func updateItemCategory(_ item: Item, to newCategory: String) {
        guard let currentItem = items.first(where: { $0.id == item.id }) else {
            editingItem = nil
            return
        }

        currentItem.category = newCategory

        do {
            try modelContext.save()
            editingItem = nil
        } catch {
            errorMessage = "分类更新失败：\(error.localizedDescription)"
            showError = true
        }
    }

    @ViewBuilder
    private func editCategorySheet(for item: Item) -> some View {
        if let currentItem = items.first(where: { $0.id == item.id }) {
            VStack(spacing: 0) {
                HStack {
                    Text("编辑分类")
                        .font(.system(size: 18, weight: .semibold))

                    Spacer()

                    Button("关闭") {
                        editingItem = nil
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("当前分类")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        Image(systemName: wardrobeCategoryIcon(for: currentItem.category))
                            .foregroundColor(.accentColor)

                        Text(currentItem.category)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(editableWardrobeCategories, id: \.self) { category in
                            Button {
                                updateItemCategory(currentItem, to: category)
                            } label: {
                                HStack {
                                    Image(systemName: wardrobeCategoryIcon(for: category))
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24)

                                    Text(category)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if currentItem.category == category {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            if category != editableWardrobeCategories.last {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.48), .medium])
            .presentationDragIndicator(.visible)
            .background(Color.wardrobeBackground)
        } else {
            VStack(spacing: 12) {
                Text("当前图片已不可用")
                    .font(.system(size: 17, weight: .semibold))

                Button("关闭") {
                    editingItem = nil
                }
            }
            .presentationDetents([.height(180)])
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
                        ForEach(wardrobeCategories, id: \.self) { category in
                            Button {
                                selectedFilter = category
                                withAnimation(.spring()) {
                                    showCategoryPicker = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: wardrobeCategoryIcon(for: category))
                                        .font(.system(size: 16))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 24)

                                    Text(category)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if selectedFilter == category {
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

                            if category != wardrobeCategories.last {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)

                Divider()

                Text("当前选择的分类会作为新图片的默认分类；选择“全部”时默认归为“其他”。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

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
                    .fill(Color.wardrobeBackground)
            )
            .padding(.horizontal, 20)
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 5)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct ModernImageCard: View {
    let item: Item
    let onTap: (() -> Void)?

    @State private var image: PlatformImage?
    @State private var isPressed = false
    @State private var showDetails = false

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.wardrobeCardBaseLight,
                    Color.wardrobeCardBaseDark
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 图片内容
            if let image {
                Image(platformImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            LinearGradient(
                gradient: Gradient(colors: [
                    .clear,
                    .black.opacity(0.06),
                    .black.opacity(0.26)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // 底部信息栏
            VStack {
                HStack {
                    categoryBadge
                        .opacity(showDetails ? 1 : 0)
                    Spacer()
                }

                Spacer()

                HStack(alignment: .bottom) {
                    if showDetails {
                        Text(formattedTimestamp)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.55))
                            )
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

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
                }
            }
            .padding(10)
        }
        .aspectRatio(1, contentMode: .fill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(isPressed ? 0.14 : 0.08),
            radius: isPressed ? 7 : 3,
            x: 0,
            y: isPressed ? 4 : 2
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: showDetails)
        .onTapGesture {
            if let onTap {
                onTap()
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetails.toggle()
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.1) {
            // 长按效果
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }
        .task(id: item.imagePath) {
            loadImage()
        }
    }

    private var categoryBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: wardrobeCategoryIcon(for: item.category))
                .font(.system(size: 10))
            Text(item.category)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }

    // MARK: - Helper Methods
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.loadImage(fileName: item.imagePath)
            DispatchQueue.main.async {
                image = loadedImage
            }
        }
    }

    private var formattedTimestamp: String {
        item.timestamp.formatted(date: .abbreviated, time: .shortened)
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }
}

struct WardrobeItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let item: Item

    @State private var colorText = ""
    @State private var season = ""
    @State private var occasion = ""
    @State private var warmthLevel = 0
    @State private var laundryStatus = ""
    @State private var noteText = ""
    @State private var saveErrorMessage = ""
    @State private var showSaveError = false
    @State private var image: PlatformImage?
    @State private var isRecognizing = false
    @State private var aiMessage = ""
    @State private var showAIMessage = false

    private let seasonOptions = ["", "春", "夏", "秋", "冬", "四季"]
    private let occasionOptions = ["", "通勤", "日常", "运动", "正式", "旅行", "居家"]
    private let laundryOptions = ["", "干净可穿", "待清洗", "清洗中"]

    var body: some View {
        Form {
            Section("图片") {
                Group {
                    if let image {
                        Image(platformImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Color.wardrobeCardBaseLight
                            ProgressView()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }

            Section("基础信息") {
                LabeledContent("分类", value: item.category)

                HStack {
                    Text("颜色")
                    Spacer()
                    TextField("未设置", text: $colorText)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 180)
                }

                Picker("季节", selection: $season) {
                    Text("未设置").tag("")
                    ForEach(seasonOptions.dropFirst(), id: \.self) { option in
                        Text(option).tag(option)
                    }
                }

                Picker("场景", selection: $occasion) {
                    Text("未设置").tag("")
                    ForEach(occasionOptions.dropFirst(), id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }

            Section("状态") {
                Picker("厚薄等级", selection: $warmthLevel) {
                    Text("未设置").tag(0)
                    Text("1 - 很薄").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                    Text("5 - 很厚").tag(5)
                }

                Picker("洗护状态", selection: $laundryStatus) {
                    Text("未设置").tag("")
                    ForEach(laundryOptions.dropFirst(), id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }

            Section("备注") {
                TextEditor(text: $noteText)
                    .frame(minHeight: 120)
            }
        }
        .navigationTitle("衣物详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("关闭")
                }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await runAIRecognition()
                    }
                } label: {
                    if isRecognizing {
                        ProgressView()
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                }
                .disabled(isRecognizing)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveChanges()
                } label: {
                    Image(systemName: "checkmark")
                }
                .accessibilityLabel("保存")
                .disabled(isRecognizing)
            }
        }
        .alert("保存失败", isPresented: $showSaveError) {
            Button("确定") { }
        } message: {
            Text(saveErrorMessage)
        }
        .alert("AI 识别", isPresented: $showAIMessage) {
            Button("确定") { }
        } message: {
            Text(aiMessage)
        }
        .onAppear {
            colorText = item.color ?? ""
            season = item.season ?? ""
            occasion = item.occasion ?? ""
            warmthLevel = item.warmthLevel ?? 0
            laundryStatus = item.laundryStatus ?? ""
            noteText = item.note ?? ""

            image = ImageManager.shared.loadImage(fileName: item.imagePath)
        }
    }

    private func saveChanges() {
        item.color = normalized(colorText)
        item.season = normalized(season)
        item.occasion = normalized(occasion)
        item.warmthLevel = warmthLevel == 0 ? nil : warmthLevel
        item.laundryStatus = normalized(laundryStatus)
        item.note = normalized(noteText)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveError = true
        }
    }

    private func runAIRecognition() async {
        guard let imageData = ImageManager.shared.loadImageData(fileName: item.imagePath) else {
            aiMessage = "无法读取图片数据，请稍后重试。"
            showAIMessage = true
            return
        }

        isRecognizing = true
        defer { isRecognizing = false }

        do {
            let recognized = try await AIImageRecognitionService.shared.recognizeWardrobeInfo(from: imageData)
            let current = AIImageRecognitionService.RecognitionResult(
                color: normalized(colorText),
                season: normalized(season),
                occasion: normalized(occasion),
                warmthLevel: warmthLevel == 0 ? nil : warmthLevel,
                laundryStatus: normalized(laundryStatus),
                note: normalized(noteText)
            )

            let merged = AIImageRecognitionService.mergeMissingFields(current: current, recognized: recognized)

            colorText = merged.color ?? ""
            season = merged.season ?? ""
            occasion = merged.occasion ?? ""
            warmthLevel = merged.warmthLevel ?? 0
            laundryStatus = merged.laundryStatus ?? ""
            noteText = merged.note ?? ""

            aiMessage = "已识别并自动补全空白字段。"
            showAIMessage = true
        } catch {
            aiMessage = error.localizedDescription
            showAIMessage = true
        }
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}

#Preview {
    WardrobeGridView()
        .modelContainer(for: Item.self, inMemory: true)
}
