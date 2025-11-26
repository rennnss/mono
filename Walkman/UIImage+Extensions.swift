import SwiftUI
import UIKit

extension UIImage {
    func dominantColors(count: Int = 4) -> [Color] {
        guard let cgImage = self.cgImage else { return [] }
        
        let width = 40
        let height = 40
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return [] }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Extract 4 quadrants
        let c1 = averageColor(data: rawData, startX: 0, startY: 0, endX: width/2, endY: height/2, width: width)
        let c2 = averageColor(data: rawData, startX: width/2, startY: 0, endX: width, endY: height/2, width: width)
        let c3 = averageColor(data: rawData, startX: 0, startY: height/2, endX: width/2, endY: height, width: width)
        let c4 = averageColor(data: rawData, startX: width/2, startY: height/2, endX: width, endY: height, width: width)
        
        return [Color(uiColor: c1), Color(uiColor: c2), Color(uiColor: c3), Color(uiColor: c4)]
    }
    
    func isDarkBackground() -> Bool {
        guard let cgImage = self.cgImage else { return false }
        
        let width = 40
        let height = 40
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return false }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let avgColor = averageColor(data: rawData, startX: 0, startY: 0, endX: width, endY: height, width: width)
        return isDark(color: avgColor)
    }
    
    private func isDark(color: UIColor) -> Bool {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Calculate luminance
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance < 0.5
    }
    
    private func averageColor(data: [UInt8], startX: Int, startY: Int, endX: Int, endY: Int, width: Int) -> UIColor {
        var r: Int = 0
        var g: Int = 0
        var b: Int = 0
        var count: Int = 0
        
        for y in startY..<endY {
            for x in startX..<endX {
                let index = (y * width + x) * 4
                r += Int(data[index])
                g += Int(data[index + 1])
                b += Int(data[index + 2])
                count += 1
            }
        }
        
        if count == 0 { return .gray }
        
        return UIColor(
            red: CGFloat(r) / CGFloat(count) / 255.0,
            green: CGFloat(g) / CGFloat(count) / 255.0,
            blue: CGFloat(b) / CGFloat(count) / 255.0,
            alpha: 1.0
        )
    }
}
