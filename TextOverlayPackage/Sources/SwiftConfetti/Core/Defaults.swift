import Foundation
import AppKit

/// canvas-confettiと同一のデフォルト設定
public struct ConfettiDefaults {
    public static let particleCount: Int = 100
    public static let angle: Double = 90
    public static let spread: Double = 120
    public static let startVelocity: Double = 45
    public static let decay: Double = 0.9
    public static let gravity: Double = 1
    public static let drift: Double = 0
    public static let ticks: Int = 120
    public static let x: Double = 0.5
    public static let y: Double = 0.5
    public static let shapes: [String] = ["square", "circle"]
    public static let zIndex: Int = 100
    public static let colors: [String] = [
        "#26ccff",
        "#a25afd",
        "#ff5e7e",
        "#88ff5a",
        "#fcff42",
        "#ffa62d",
        "#ff36ff"
    ]
    public static let disableForReducedMotion: Bool = false
    public static let scalar: Double = 1
}

/// RGB色構造体
public struct RGB {
    let r: Int
    let g: Int
    let b: Int

    var nsColor: NSColor {
        NSColor(red: Double(r) / 255.0,
                green: Double(g) / 255.0,
                blue: Double(b) / 255.0,
                alpha: 1.0)
    }
}

/// 色変換ユーティリティ
public func hexToRgb(_ str: String) -> RGB {
    var val = str.replacingOccurrences(of: "[^0-9a-f]", with: "", options: .regularExpression, range: nil)

    if val.count < 6 {
        if val.count >= 1 {
            val = String(repeating: String(val[val.startIndex]), count: 2) +
                  String(repeating: String(val[val.index(val.startIndex, offsetBy: min(1, val.count - 1))]), count: 2) +
                  String(repeating: String(val[val.index(val.startIndex, offsetBy: min(2, val.count - 1))]), count: 2)
        }
    }

    let r = Int(val.prefix(2), radix: 16) ?? 0
    let g = Int(val.dropFirst(2).prefix(2), radix: 16) ?? 0
    let b = Int(val.dropFirst(4).prefix(2), radix: 16) ?? 0

    return RGB(r: r, g: g, b: b)
}

public func colorsToRgb(_ colors: [String]) -> [RGB] {
    return colors.map(hexToRgb)
}

/// オプション構造体
public struct ConfettiOptions: Sendable {
    public var particleCount: Int
    public var angle: Double
    public var spread: Double
    public var startVelocity: Double
    public var decay: Double
    public var gravity: Double
    public var drift: Double
    public var ticks: Int
    public var origin: Origin
    public var colors: [String]
    public var shapes: [ConfettiShape]
    public var scalar: Double
    public var zIndex: Int
    public var disableForReducedMotion: Bool
    public var flat: Bool

    public struct Origin: Sendable {
        public var x: Double
        public var y: Double

        public init(x: Double = 0.5, y: Double = 0.5) {
            self.x = x
            self.y = y
        }
    }

    public init(
        particleCount: Int? = nil,
        angle: Double? = nil,
        spread: Double? = nil,
        startVelocity: Double? = nil,
        decay: Double? = nil,
        gravity: Double? = nil,
        drift: Double? = nil,
        ticks: Int? = nil,
        origin: Origin? = nil,
        colors: [String]? = nil,
        shapes: [ConfettiShape]? = nil,
        scalar: Double? = nil,
        zIndex: Int? = nil,
        disableForReducedMotion: Bool? = nil,
        flat: Bool = false
    ) {
        self.particleCount = particleCount ?? ConfettiDefaults.particleCount
        self.angle = angle ?? ConfettiDefaults.angle
        self.spread = spread ?? ConfettiDefaults.spread
        self.startVelocity = startVelocity ?? ConfettiDefaults.startVelocity
        self.decay = decay ?? ConfettiDefaults.decay
        self.gravity = gravity ?? ConfettiDefaults.gravity
        self.drift = drift ?? ConfettiDefaults.drift
        self.ticks = ticks ?? ConfettiDefaults.ticks
        self.origin = origin ?? Origin()
        self.colors = colors ?? ConfettiDefaults.colors
        self.shapes = shapes ?? [.square, .circle]
        self.scalar = scalar ?? ConfettiDefaults.scalar
        self.zIndex = zIndex ?? ConfettiDefaults.zIndex
        self.disableForReducedMotion = disableForReducedMotion ?? ConfettiDefaults.disableForReducedMotion
        self.flat = flat
    }

    public static let `default` = ConfettiOptions()
}

/// NSImageのSendableラッパー
public struct SendableImage: @unchecked Sendable {
    public let image: NSImage

    public init(_ image: NSImage) {
        self.image = image
    }
}

/// 紙吹雪の形状
public enum ConfettiShape: Sendable, Equatable {
    case square
    case circle
    case star
    case path(String, matrix: [Double]?)
    case bitmap(SendableImage, matrix: [Double]?)
    case text(String, scalar: Double?, fontFamily: String?, color: String?)

    public static func == (lhs: ConfettiShape, rhs: ConfettiShape) -> Bool {
        switch (lhs, rhs) {
        case (.square, .square), (.circle, .circle), (.star, .star):
            return true
        case let (.path(lPath, lMatrix), .path(rPath, rMatrix)):
            return lPath == rPath && lMatrix == rMatrix
        case let (.bitmap(lImage, lMatrix), .bitmap(rImage, rMatrix)):
            return lImage.image == rImage.image && lMatrix == rMatrix
        case let (.text(lText, lScalar, lFont, lColor), .text(rText, rScalar, rFont, rColor)):
            return lText == rText && lScalar == rScalar && lFont == rFont && lColor == rColor
        default:
            return false
        }
    }
}
