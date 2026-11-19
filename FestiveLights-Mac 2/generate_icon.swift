import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let iconsetPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let colorSpace = CGColorSpaceCreateDeviceRGB()

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

func writeIcon(size: Int, to url: URL) {
    let s = CGFloat(size)
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else { return }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let inset = s * 0.08
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let bgPath = CGPath(roundedRect: rect, cornerWidth: s * 0.22, cornerHeight: s * 0.22, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    if let grad = CGGradient(
        colorsSpace: colorSpace,
        colors: [rgba(0.09, 0.11, 0.20, 1.0), rgba(0.04, 0.05, 0.11, 1.0)] as CFArray,
        locations: [0.0, 1.0]
    ) {
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])
    }

    // Festive wire curve
    ctx.setStrokeColor(rgba(0.20, 0.45, 0.28, 1.0))
    ctx.setLineWidth(s * 0.025)
    ctx.move(to: CGPoint(x: inset, y: s * 0.72))
    ctx.addQuadCurve(to: CGPoint(x: s - inset, y: s * 0.72), control: CGPoint(x: s * 0.5, y: s * 0.48))
    ctx.strokePath()

    // 3 glowing bulbs (Red, Warm Orange/Pumpkin, Emerald)
    let bulbs: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
        (0.28, 0.54, 1.0, 0.28, 0.28),
        (0.50, 0.45, 1.0, 0.62, 0.12),
        (0.72, 0.54, 0.22, 0.88, 0.48)
    ]
    for (bx, by, r, g, b) in bulbs {
        let center = CGPoint(x: s * bx, y: s * by)
        if let glow = CGGradient(
            colorsSpace: colorSpace,
            colors: [rgba(r, g, b, 0.85), rgba(r, g, b, 0.0)] as CFArray,
            locations: [0.0, 1.0]
        ) {
            ctx.drawRadialGradient(glow, startCenter: center, startRadius: 0, endCenter: center, endRadius: s * 0.22, options: [])
        }
        ctx.setFillColor(rgba(r, g, b, 1.0))
        ctx.fillEllipse(in: CGRect(x: center.x - s * 0.075, y: center.y - s * 0.095, width: s * 0.15, height: s * 0.19))
        ctx.setFillColor(rgba(1.0, 1.0, 1.0, 0.6))
        ctx.fillEllipse(in: CGRect(x: center.x - s * 0.038, y: center.y + s * 0.01, width: s * 0.032, height: s * 0.055))
    }

    ctx.restoreGState()

    guard let image = ctx.makeImage(),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return
    }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let specs: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for (px, name) in specs {
    writeIcon(size: px, to: URL(fileURLWithPath: "\(iconsetPath)/\(name)"))
}
