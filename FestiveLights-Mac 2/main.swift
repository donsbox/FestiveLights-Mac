import Cocoa

// MARK: - Models & Preferences

enum FestiveTheme: String, CaseIterable {
    case christmas = "christmas"
    case halloween = "halloween"

    var displayName: String {
        switch self {
        case .christmas: return "圣诞彩灯 (Christmas)"
        case .halloween: return "万圣节南瓜灯 (Halloween)"
        }
    }

    var menuSymbol: String {
        switch self {
        case .christmas: return "sparkles"
        case .halloween: return "flame.fill"
        }
    }
}

enum LightMode: String, CaseIterable {
    case breathe = "breathe"
    case twinkle = "twinkle"
    case steady = "steady"

    var displayName: String {
        switch self {
        case .breathe: return "柔和呼吸"
        case .twinkle: return "节日闪烁"
        case .steady: return "温暖常亮"
        }
    }
}

enum DropSize: String, CaseIterable {
    case compact = "compact"
    case standard = "standard"
    case large = "large"

    var displayName: String {
        switch self {
        case .compact: return "紧凑 (轻盈)"
        case .standard: return "标准 (推荐)"
        case .large: return "宽大 (氛围感)"
        }
    }

    var windowHeight: CGFloat {
        switch self {
        case .compact: return 82
        case .standard: return 112
        case .large: return 146
        }
    }

    var scale: CGFloat {
        switch self {
        case .compact: return 0.78
        case .standard: return 1.0
        case .large: return 1.25
        }
    }
}

enum BrightnessLevel: Double, CaseIterable {
    case low = 0.55
    case medium = 0.80
    case high = 1.0

    var displayName: String {
        switch self {
        case .low: return "柔和 (55%)"
        case .medium: return "适中 (80%)"
        case .high: return "明亮 (100%)"
        }
    }
}

final class AppSettings {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    var theme: FestiveTheme {
        get { FestiveTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .christmas }
        set { defaults.set(newValue.rawValue, forKey: "theme") }
    }

    var mode: LightMode {
        get { LightMode(rawValue: defaults.string(forKey: "mode") ?? "") ?? .breathe }
        set { defaults.set(newValue.rawValue, forKey: "mode") }
    }

    var dropSize: DropSize {
        get { DropSize(rawValue: defaults.string(forKey: "dropSize") ?? "") ?? .standard }
        set { defaults.set(newValue.rawValue, forKey: "dropSize") }
    }

    var brightness: BrightnessLevel {
        get {
            let val = defaults.double(forKey: "brightness")
            return BrightnessLevel(rawValue: val) ?? .high
        }
        set { defaults.set(newValue.rawValue, forKey: "brightness") }
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: "isEnabled") == nil ? true : defaults.bool(forKey: "isEnabled") }
        set { defaults.set(newValue, forKey: "isEnabled") }
    }
}

// MARK: - Festive Lights View (CoreGraphics)

final class FestiveLightsView: NSView {
    var theme: FestiveTheme = .christmas { didSet { needsDisplay = true } }
    var mode: LightMode = .breathe { didSet { needsDisplay = true } }
    var dropScale: CGFloat = 1.0 { didSet { needsDisplay = true } }
    var brightness: CGFloat = 1.0 { didSet { needsDisplay = true } }
    var phase: CGFloat = 0.0

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    // Christmas bulb palette (Red, Warm Gold, Emerald, Ice Blue, Warm White)
    private let christmasColors: [NSColor] = [
        NSColor(calibratedRed: 1.00, green: 0.24, blue: 0.26, alpha: 1.0),
        NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.20, alpha: 1.0),
        NSColor(calibratedRed: 0.18, green: 0.85, blue: 0.45, alpha: 1.0),
        NSColor(calibratedRed: 0.28, green: 0.72, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.76, alpha: 1.0)
    ]

    // Halloween accent fairy lights (Violet, Amber, Toxic Green)
    private let halloweenAccents: [NSColor] = [
        NSColor(calibratedRed: 0.68, green: 0.30, blue: 1.00, alpha: 1.0),
        NSColor(calibratedRed: 1.00, green: 0.54, blue: 0.10, alpha: 1.0),
        NSColor(calibratedRed: 0.56, green: 0.92, blue: 0.20, alpha: 1.0)
    ]

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)

        switch theme {
        case .christmas:
            drawChristmasLights(in: ctx)
        case .halloween:
            drawHalloweenLanterns(in: ctx)
        }
    }

    private func intensity(for index: Int) -> CGFloat {
        let base: CGFloat
        switch mode {
        case .steady:
            base = 0.95
        case .breathe:
            let wave = sin(phase * 1.4 + CGFloat(index) * 0.65)
            base = 0.62 + 0.38 * ((wave + 1.0) * 0.5)
        case .twinkle:
            let fast = sin(phase * 3.8 + CGFloat(index) * 1.9)
            let slow = cos(phase * 1.7 + CGFloat(index) * 0.7)
            let combined = max(0.0, (fast * 0.65 + slow * 0.35 + 1.0) * 0.5)
            base = 0.35 + 0.65 * CGFloat(pow(Double(combined), 1.8))
        }
        return base * brightness
    }

    // MARK: - Christmas String Lights

    private func drawChristmasLights(in ctx: CGContext) {
        let width = bounds.width
        let spanWidth: CGFloat = 220 * dropScale
        let spanCount = max(1, Int(ceil(width / spanWidth)))
        let actualSpan = width / CGFloat(spanCount)
        let sagDepth: CGFloat = 34 * dropScale

        // 1. Draw main dark-green braided cable
        ctx.saveGState()
        let wirePath = CGMutablePath()
        for i in 0..<spanCount {
            let startX = CGFloat(i) * actualSpan
            let endX = startX + actualSpan
            let ctrlX = (startX + endX) * 0.5
            let ctrlY = sagDepth * 1.85
            if i == 0 {
                wirePath.move(to: CGPoint(x: startX, y: 1))
            }
            wirePath.addQuadCurve(to: CGPoint(x: endX, y: 1), control: CGPoint(x: ctrlX, y: ctrlY))
        }

        ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: NSColor.black.withAlphaComponent(0.35).cgColor)
        ctx.addPath(wirePath)
        ctx.setStrokeColor(NSColor(calibratedRed: 0.10, green: 0.24, blue: 0.15, alpha: 0.95).cgColor)
        ctx.setLineWidth(2.4 * dropScale)
        ctx.setLineCap(.round)
        ctx.strokePath()
        ctx.restoreGState()

        // 2. Draw bulbs along each catenary span
        let bulbsPerSpan = 5
        var globalIndex = 0

        for i in 0..<spanCount {
            let startX = CGFloat(i) * actualSpan
            let endX = startX + actualSpan
            let ctrlX = (startX + endX) * 0.5
            let ctrlY = sagDepth * 1.85

            for j in 0..<bulbsPerSpan {
                let t = (CGFloat(j) + 0.5) / CGFloat(bulbsPerSpan)
                let pt = quadBezierPoint(
                    p0: CGPoint(x: startX, y: 1),
                    p1: CGPoint(x: ctrlX, y: ctrlY),
                    p2: CGPoint(x: endX, y: 1),
                    t: t
                )
                let tangent = quadBezierTangent(
                    p0: CGPoint(x: startX, y: 1),
                    p1: CGPoint(x: ctrlX, y: ctrlY),
                    p2: CGPoint(x: endX, y: 1),
                    t: t
                )
                let wireAngle = atan2(tangent.y, tangent.x) * 0.35
                let sway = sin(phase * 1.1 + CGFloat(globalIndex) * 0.9) * 0.04
                let color = christmasColors[globalIndex % christmasColors.count]
                let glow = intensity(for: globalIndex)

                drawChristmasBulb(
                    in: ctx,
                    at: pt,
                    angle: wireAngle + sway,
                    color: color,
                    glow: glow,
                    scale: dropScale
                )
                globalIndex += 1
            }
        }
    }

    private func drawChristmasBulb(
        in ctx: CGContext,
        at origin: CGPoint,
        angle: CGFloat,
        color: NSColor,
        glow: CGFloat,
        scale: CGFloat
    ) {
        ctx.saveGState()
        ctx.translateBy(x: origin.x, y: origin.y)
        ctx.rotate(by: angle)

        // Short drop cord
        let cordLen: CGFloat = 5 * scale
        ctx.setStrokeColor(NSColor(calibratedRed: 0.10, green: 0.24, blue: 0.15, alpha: 0.95).cgColor)
        ctx.setLineWidth(1.6 * scale)
        ctx.move(to: .zero)
        ctx.addLine(to: CGPoint(x: 0, y: cordLen))
        ctx.strokePath()

        // Socket
        let socketW: CGFloat = 7.5 * scale
        let socketH: CGFloat = 7.0 * scale
        let socketRect = CGRect(x: -socketW / 2, y: cordLen, width: socketW, height: socketH)
        let socketPath = CGPath(roundedRect: socketRect, cornerWidth: 1.5 * scale, cornerHeight: 1.5 * scale, transform: nil)
        ctx.addPath(socketPath)
        ctx.setFillColor(NSColor(calibratedRed: 0.15, green: 0.28, blue: 0.18, alpha: 1.0).cgColor)
        ctx.fillPath()

        // Radial Glow Halo
        let bulbTopY = cordLen + socketH - 1 * scale
        let bulbH: CGFloat = 22 * scale
        let bulbW: CGFloat = 13.5 * scale
        let glowCenter = CGPoint(x: 0, y: bulbTopY + bulbH * 0.55)
        let glowRadius = 30 * scale * (0.75 + 0.35 * glow)

        drawRadialGlow(in: ctx, center: glowCenter, radius: glowRadius, color: color, alpha: 0.58 * glow)

        // Teardrop glass bulb path
        let bulbPath = CGMutablePath()
        bulbPath.move(to: CGPoint(x: -socketW * 0.42, y: bulbTopY))
        bulbPath.addCurve(
            to: CGPoint(x: 0, y: bulbTopY + bulbH),
            control1: CGPoint(x: -bulbW * 0.72, y: bulbTopY + bulbH * 0.48),
            control2: CGPoint(x: -bulbW * 0.38, y: bulbTopY + bulbH * 0.96)
        )
        bulbPath.addCurve(
            to: CGPoint(x: socketW * 0.42, y: bulbTopY),
            control1: CGPoint(x: bulbW * 0.38, y: bulbTopY + bulbH * 0.96),
            control2: CGPoint(x: bulbW * 0.72, y: bulbTopY + bulbH * 0.48)
        )
        bulbPath.closeSubpath()

        ctx.saveGState()
        ctx.addPath(bulbPath)
        ctx.clip()

        let brightCore = color.blended(withFraction: 0.55 * glow, of: .white) ?? color
        let dimEdge = color.blended(withFraction: 0.32, of: .black) ?? color
        if let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [brightCore.cgColor, color.cgColor, dimEdge.cgColor] as CFArray,
            locations: [0.0, 0.55, 1.0]
        ) {
            ctx.drawRadialGradient(
                grad,
                startCenter: CGPoint(x: -1.5 * scale, y: bulbTopY + bulbH * 0.42),
                startRadius: 1 * scale,
                endCenter: CGPoint(x: 0, y: bulbTopY + bulbH * 0.52),
                endRadius: bulbH * 0.65,
                options: [.drawsAfterEndLocation]
            )
        }
        ctx.restoreGState()

        // Specular highlight
        let specRect = CGRect(
            x: -bulbW * 0.28,
            y: bulbTopY + bulbH * 0.24,
            width: bulbW * 0.22,
            height: bulbH * 0.34
        )
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.55 * glow + 0.15).cgColor)
        ctx.fillEllipse(in: specRect)

        ctx.restoreGState()
    }

    // MARK: - Halloween Pumpkin Lanterns

    private func drawHalloweenLanterns(in ctx: CGContext) {
        let width = bounds.width
        let spanWidth: CGFloat = 250 * dropScale
        let spanCount = max(1, Int(ceil(width / spanWidth)))
        let actualSpan = width / CGFloat(spanCount)
        let sagDepth: CGFloat = 32 * dropScale

        // 1. Dark twisted vine cord
        ctx.saveGState()
        let vinePath = CGMutablePath()
        for i in 0..<spanCount {
            let startX = CGFloat(i) * actualSpan
            let endX = startX + actualSpan
            let ctrlX = (startX + endX) * 0.5
            let ctrlY = sagDepth * 1.85
            if i == 0 {
                vinePath.move(to: CGPoint(x: startX, y: 1))
            }
            vinePath.addQuadCurve(to: CGPoint(x: endX, y: 1), control: CGPoint(x: ctrlX, y: ctrlY))
        }
        ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 3, color: NSColor.black.withAlphaComponent(0.45).cgColor)
        ctx.addPath(vinePath)
        ctx.setStrokeColor(NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.18, alpha: 0.96).cgColor)
        ctx.setLineWidth(2.6 * dropScale)
        ctx.setLineCap(.round)
        ctx.strokePath()
        ctx.restoreGState()

        // 2. Alternating Pumpkins & Mini Fairy Bulbs
        let itemsPerSpan = 4
        var globalIndex = 0

        for i in 0..<spanCount {
            let startX = CGFloat(i) * actualSpan
            let endX = startX + actualSpan
            let ctrlX = (startX + endX) * 0.5
            let ctrlY = sagDepth * 1.85

            for j in 0..<itemsPerSpan {
                let t = (CGFloat(j) + 0.5) / CGFloat(itemsPerSpan)
                let pt = quadBezierPoint(
                    p0: CGPoint(x: startX, y: 1),
                    p1: CGPoint(x: ctrlX, y: ctrlY),
                    p2: CGPoint(x: endX, y: 1),
                    t: t
                )
                let sway = sin(phase * 0.95 + CGFloat(globalIndex) * 1.15) * 0.055
                let glow = intensity(for: globalIndex)

                if globalIndex % 2 == 0 {
                    drawPumpkinLantern(
                        in: ctx,
                        at: pt,
                        angle: sway,
                        glow: glow,
                        variant: (globalIndex / 2) % 2,
                        scale: dropScale
                    )
                } else {
                    let accent = halloweenAccents[(globalIndex / 2) % halloweenAccents.count]
                    drawChristmasBulb(
                        in: ctx,
                        at: pt,
                        angle: sway * 1.2,
                        color: accent,
                        glow: glow,
                        scale: dropScale * 0.72
                    )
                }
                globalIndex += 1
            }
        }
    }

    private func drawPumpkinLantern(
        in ctx: CGContext,
        at origin: CGPoint,
        angle: CGFloat,
        glow: CGFloat,
        variant: Int,
        scale: CGFloat
    ) {
        ctx.saveGState()
        ctx.translateBy(x: origin.x, y: origin.y)
        ctx.rotate(by: angle)

        // Hanging cord
        let cordLen: CGFloat = 10 * scale
        ctx.setStrokeColor(NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.18, alpha: 0.95).cgColor)
        ctx.setLineWidth(1.8 * scale)
        ctx.move(to: .zero)
        ctx.addLine(to: CGPoint(x: 0, y: cordLen))
        ctx.strokePath()

        let pumpkinW: CGFloat = 32 * scale
        let pumpkinH: CGFloat = 25 * scale
        let centerY: CGFloat = cordLen + 5 * scale + pumpkinH * 0.5
        let center = CGPoint(x: 0, y: centerY)

        // Warm candlelight outer glow
        let glowColor = NSColor(calibratedRed: 1.0, green: 0.56, blue: 0.08, alpha: 1.0)
        drawRadialGlow(
            in: ctx,
            center: center,
            radius: 36 * scale * (0.78 + 0.30 * glow),
            color: glowColor,
            alpha: 0.55 * glow
        )

        // Green curved stem
        let stemPath = CGMutablePath()
        stemPath.move(to: CGPoint(x: -2.2 * scale, y: centerY - pumpkinH * 0.44))
        stemPath.addQuadCurve(
            to: CGPoint(x: 2.8 * scale, y: centerY - pumpkinH * 0.72),
            control: CGPoint(x: -1.0 * scale, y: centerY - pumpkinH * 0.68)
        )
        stemPath.addLine(to: CGPoint(x: 4.5 * scale, y: centerY - pumpkinH * 0.64))
        stemPath.addQuadCurve(
            to: CGPoint(x: 2.2 * scale, y: centerY - pumpkinH * 0.44),
            control: CGPoint(x: 1.8 * scale, y: centerY - pumpkinH * 0.56)
        )
        stemPath.closeSubpath()
        ctx.addPath(stemPath)
        ctx.setFillColor(NSColor(calibratedRed: 0.24, green: 0.46, blue: 0.18, alpha: 1.0).cgColor)
        ctx.fillPath()

        // Pumpkin ribbed body
        let leftLobe = CGRect(
            x: -pumpkinW * 0.50,
            y: centerY - pumpkinH * 0.46,
            width: pumpkinW * 0.56,
            height: pumpkinH * 0.92
        )
        let rightLobe = CGRect(
            x: -pumpkinW * 0.06,
            y: centerY - pumpkinH * 0.46,
            width: pumpkinW * 0.56,
            height: pumpkinH * 0.92
        )
        let midLobe = CGRect(
            x: -pumpkinW * 0.28,
            y: centerY - pumpkinH * 0.50,
            width: pumpkinW * 0.56,
            height: pumpkinH * 1.00
        )

        let darkOrange = NSColor(calibratedRed: 0.84, green: 0.34, blue: 0.05, alpha: 1.0)
        let brightOrange = NSColor(calibratedRed: 0.99, green: 0.52, blue: 0.10, alpha: 1.0)
        let strokeOrange = NSColor(calibratedRed: 0.56, green: 0.20, blue: 0.02, alpha: 0.75)

        ctx.setFillColor(darkOrange.cgColor)
        ctx.fillEllipse(in: leftLobe)
        ctx.fillEllipse(in: rightLobe)

        ctx.setFillColor(brightOrange.cgColor)
        ctx.fillEllipse(in: midLobe)

        ctx.setStrokeColor(strokeOrange.cgColor)
        ctx.setLineWidth(1.0 * scale)
        ctx.strokeEllipse(in: midLobe)

        // Carved glowing eyes & mouth
        let faceColor = NSColor(
            calibratedRed: 1.0,
            green: 0.92 + 0.06 * glow,
            blue: 0.45 + 0.35 * glow,
            alpha: 0.75 + 0.25 * glow
        )
        ctx.saveGState()
        ctx.setShadow(
            offset: .zero,
            blur: 5 * scale * glow,
            color: NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.2, alpha: 0.9 * glow).cgColor
        )
        ctx.setFillColor(faceColor.cgColor)

        let eyeY = centerY - pumpkinH * 0.08
        let eyeOffsetX = pumpkinW * 0.19
        let eyeSize = 4.6 * scale

        let leftEye = CGMutablePath()
        leftEye.move(to: CGPoint(x: -eyeOffsetX, y: eyeY - eyeSize * 0.7))
        leftEye.addLine(to: CGPoint(x: -eyeOffsetX - eyeSize * 0.75, y: eyeY + eyeSize * 0.45))
        leftEye.addLine(to: CGPoint(x: -eyeOffsetX + eyeSize * 0.65, y: eyeY + eyeSize * 0.45))
        leftEye.closeSubpath()
        ctx.addPath(leftEye)

        let rightEye = CGMutablePath()
        rightEye.move(to: CGPoint(x: eyeOffsetX, y: eyeY - eyeSize * 0.7))
        rightEye.addLine(to: CGPoint(x: eyeOffsetX - eyeSize * 0.65, y: eyeY + eyeSize * 0.45))
        rightEye.addLine(to: CGPoint(x: eyeOffsetX + eyeSize * 0.75, y: eyeY + eyeSize * 0.45))
        rightEye.closeSubpath()
        ctx.addPath(rightEye)

        let mouthY = centerY + pumpkinH * 0.14
        let mouthW = pumpkinW * 0.32
        let mouth = CGMutablePath()
        if variant == 0 {
            mouth.move(to: CGPoint(x: -mouthW, y: mouthY - 1.0 * scale))
            mouth.addLine(to: CGPoint(x: -mouthW * 0.55, y: mouthY + 3.4 * scale))
            mouth.addLine(to: CGPoint(x: -mouthW * 0.15, y: mouthY + 1.2 * scale))
            mouth.addLine(to: CGPoint(x: 0, y: mouthY + 4.0 * scale))
            mouth.addLine(to: CGPoint(x: mouthW * 0.15, y: mouthY + 1.2 * scale))
            mouth.addLine(to: CGPoint(x: mouthW * 0.55, y: mouthY + 3.4 * scale))
            mouth.addLine(to: CGPoint(x: mouthW, y: mouthY - 1.0 * scale))
            mouth.addQuadCurve(
                to: CGPoint(x: -mouthW, y: mouthY - 1.0 * scale),
                control: CGPoint(x: 0, y: mouthY + 1.2 * scale)
            )
        } else {
            mouth.move(to: CGPoint(x: -mouthW * 0.9, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: mouthW * 0.9, y: mouthY),
                control: CGPoint(x: 0, y: mouthY + 5.8 * scale)
            )
            mouth.addQuadCurve(
                to: CGPoint(x: -mouthW * 0.9, y: mouthY),
                control: CGPoint(x: 0, y: mouthY + 1.6 * scale)
            )
        }
        mouth.closeSubpath()
        ctx.addPath(mouth)
        ctx.fillPath()
        ctx.restoreGState()

        ctx.restoreGState()
    }

    // MARK: - Helpers

    private func drawRadialGlow(in ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor, alpha: CGFloat) {
        let c1 = color.withAlphaComponent(alpha).cgColor
        let c2 = color.withAlphaComponent(alpha * 0.35).cgColor
        let c3 = color.withAlphaComponent(0.0).cgColor
        guard let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [c1, c2, c3] as CFArray,
            locations: [0.0, 0.45, 1.0]
        ) else { return }
        ctx.drawRadialGradient(
            grad,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: radius,
            options: []
        )
    }

    private func quadBezierPoint(p0: CGPoint, p1: CGPoint, p2: CGPoint, t: CGFloat) -> CGPoint {
        let u = 1.0 - t
        let x = u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x
        let y = u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    private func quadBezierTangent(p0: CGPoint, p1: CGPoint, p2: CGPoint, t: CGFloat) -> CGPoint {
        let dx = 2 * (1 - t) * (p1.x - p0.x) + 2 * t * (p2.x - p1.x)
        let dy = 2 * (1 - t) * (p1.y - p0.y) + 2 * t * (p2.y - p1.y)
        return CGPoint(x: dx, y: dy)
    }
}

// MARK: - Overlay Window Controller

final class OverlayWindow: NSWindow {
    let lightsView: FestiveLightsView

    init(for screen: NSScreen, height: CGFloat) {
        let topY = screen.visibleFrame.maxY
        let frame = NSRect(
            x: screen.frame.minX,
            y: topY - height,
            width: screen.frame.width,
            height: height
        )
        self.lightsView = FestiveLightsView(frame: NSRect(origin: .zero, size: frame.size))
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) - 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.contentView = lightsView
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var overlayWindows: [OverlayWindow] = []
    private var animationTimer: Timer?
    private var currentPhase: CGFloat = 0.0
    private let settings = AppSettings.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        rebuildWindows()
        startAnimationTimer()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusIcon()
        rebuildMenu()
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        if let img = NSImage(systemSymbolName: settings.theme.menuSymbol, accessibilityDescription: "Festive Lights") {
            img.isTemplate = true
            button.image = img
            button.title = ""
        } else {
            button.image = nil
            button.title = settings.theme == .christmas ? "🎄" : "🎃"
        }
        button.alphaValue = settings.isEnabled ? 1.0 : 0.45
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: settings.isEnabled ? "隐藏彩灯" : "显示彩灯",
            action: #selector(toggleLights),
            keyEquivalent: "h"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())

        let themeHeader = NSMenuItem(title: "主题切换", action: nil, keyEquivalent: "")
        themeHeader.isEnabled = false
        menu.addItem(themeHeader)

        for theme in FestiveTheme.allCases {
            let item = NSMenuItem(title: theme.displayName, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme.rawValue
            item.state = (settings.theme == theme) ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let modeItem = NSMenuItem(title: "灯光动效", action: nil, keyEquivalent: "")
        let modeSubmenu = NSMenu()
        for mode in LightMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (settings.mode == mode) ? .on : .off
            modeSubmenu.addItem(item)
        }
        modeItem.submenu = modeSubmenu
        menu.addItem(modeItem)

        let sizeItem = NSMenuItem(title: "下坠尺寸", action: nil, keyEquivalent: "")
        let sizeSubmenu = NSMenu()
        for size in DropSize.allCases {
            let item = NSMenuItem(title: size.displayName, action: #selector(selectSize(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = size.rawValue
            item.state = (settings.dropSize == size) ? .on : .off
            sizeSubmenu.addItem(item)
        }
        sizeItem.submenu = sizeSubmenu
        menu.addItem(sizeItem)

        let brightItem = NSMenuItem(title: "亮度调节", action: nil, keyEquivalent: "")
        let brightSubmenu = NSMenu()
        for level in BrightnessLevel.allCases {
            let item = NSMenuItem(title: level.displayName, action: #selector(selectBrightness(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = level.rawValue
            item.state = (settings.brightness == level) ? .on : .off
            brightSubmenu.addItem(item)
        }
        brightItem.submenu = brightSubmenu
        menu.addItem(brightItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 FestiveLights", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func rebuildWindows() {
        for win in overlayWindows {
            win.orderOut(nil)
            win.close()
        }
        overlayWindows.removeAll()

        let height = settings.dropSize.windowHeight
        for screen in NSScreen.screens {
            let win = OverlayWindow(for: screen, height: height)
            syncViewSettings(win.lightsView)
            if settings.isEnabled {
                win.orderFrontRegardless()
            }
            overlayWindows.append(win)
        }
    }

    private func syncViewSettings(_ view: FestiveLightsView) {
        view.theme = settings.theme
        view.mode = settings.mode
        view.dropScale = settings.dropSize.scale
        view.brightness = CGFloat(settings.brightness.rawValue)
        view.phase = currentPhase
        view.needsDisplay = true
    }

    private func startAnimationTimer() {
        animationTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self, self.settings.isEnabled else { return }
            self.currentPhase += 0.055
            for win in self.overlayWindows {
                win.lightsView.phase = self.currentPhase
                win.lightsView.needsDisplay = true
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    // MARK: - Actions

    @objc private func screensChanged() {
        rebuildWindows()
    }

    @objc private func toggleLights() {
        settings.isEnabled.toggle()
        for win in overlayWindows {
            if settings.isEnabled {
                win.orderFrontRegardless()
            } else {
                win.orderOut(nil)
            }
        }
        updateStatusIcon()
        rebuildMenu()
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let theme = FestiveTheme(rawValue: raw) else { return }
        settings.theme = theme
        if !settings.isEnabled { settings.isEnabled = true }
        for win in overlayWindows {
            syncViewSettings(win.lightsView)
            win.orderFrontRegardless()
        }
        updateStatusIcon()
        rebuildMenu()
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = LightMode(rawValue: raw) else { return }
        settings.mode = mode
        for win in overlayWindows {
            syncViewSettings(win.lightsView)
        }
        rebuildMenu()
    }

    @objc private func selectSize(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let size = DropSize(rawValue: raw) else { return }
        settings.dropSize = size
        rebuildWindows()
        rebuildMenu()
    }

    @objc private func selectBrightness(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? Double,
              let level = BrightnessLevel(rawValue: raw) else { return }
        settings.brightness = level
        for win in overlayWindows {
            syncViewSettings(win.lightsView)
        }
        rebuildMenu()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
