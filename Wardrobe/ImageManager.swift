//
//  ImageManager.swift
//  Wardrobe
//
//  Created by James Leong on 2026/3/7.
//

import Foundation
import UIKit

class ImageManager {
    static let shared = ImageManager()
    
    private let fileManager = FileManager.default
    private lazy var documentsDirectory: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()
    
    private lazy var imagesDirectory: URL = {
        let path = documentsDirectory.appendingPathComponent("WardrobeImages")
        if !fileManager.fileExists(atPath: path.path) {
            try? fileManager.createDirectory(at: path, withIntermediateDirectories: true)
        }
        return path
    }()
    
    // MARK: - 保存图片
    func saveImage(_ image: UIImage, category: String = "其他") throws -> String {
        let fileName = "\(UUID().uuidString)_\(Date().timeIntervalSince1970).jpg"
        let filePath = imagesDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ImageError.compressionFailed
        }
        
        try imageData.write(to: filePath)
        return fileName
    }
    
    // MARK: - 读取图片
    func loadImage(fileName: String) -> UIImage? {
        let filePath = imagesDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: filePath.path)
    }
    
    // MARK: - 删除图片
    func deleteImage(fileName: String) throws {
        let filePath = imagesDirectory.appendingPathComponent(fileName)
        try fileManager.removeItem(at: filePath)
    }
    
    // MARK: - 获取所有图片文件名
    func getAllImageFileNames() -> [String] {
        do {
            return try fileManager.contentsOfDirectory(atPath: imagesDirectory.path)
                .filter { $0.hasSuffix(".jpg") }
                .sorted(by: >)  // 最新的文件在前
        } catch {
            return []
        }
    }
    
    // MARK: - 清理未使用的文件
    func cleanupUnusedImages(usedFileNames: Set<String>) throws {
        let allFiles = getAllImageFileNames()
        let unusedFiles = allFiles.filter { !usedFileNames.contains($0) }
        
        for fileName in unusedFiles {
            try deleteImage(fileName: fileName)
        }
    }
}

enum ImageError: Error {
    case compressionFailed
    case saveFailed
    case loadFailed
}
