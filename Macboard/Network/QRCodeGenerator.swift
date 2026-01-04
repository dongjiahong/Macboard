import Foundation
import CoreImage
import AppKit

/// 二维码生成器
struct QRCodeGenerator {
    
    /// 生成二维码图片
    /// - Parameters:
    ///   - content: 二维码内容 (如 URL)
    ///   - size: 输出尺寸
    /// - Returns: NSImage 或 nil
    static func generate(from content: String, size: CGFloat = 200) -> NSImage? {
        guard let data = content.data(using: .utf8) else { return nil }
        
        // 使用 CoreImage 创建二维码
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 高纠错级别
        
        guard let ciImage = filter.outputImage else { return nil }
        
        // 放大二维码 (原始二维码很小)
        let scale = size / ciImage.extent.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: transform)
        
        // 转换为 NSImage
        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
}
