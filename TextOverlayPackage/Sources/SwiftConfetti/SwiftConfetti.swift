import Foundation
import AppKit
import SwiftUI

/// canvas-confettiのSwift完全移植版
@MainActor
public class SwiftConfetti {
    private weak var canvas: NSView?
    private var renderer: ConfettiRenderer?
    private var animationObj: ConfettiAnimation?
    private var isLibCanvas: Bool
    private var allowResize: Bool
    private var globalDisableForReducedMotion: Bool
    private var preferLessMotion: Bool

    // canvas-confettiと同じデフォルトインスタンス（遅延初期化）
    private static var defaultInstance: SwiftConfetti?

    /// デフォルトのfire関数（canvas-confettiと互換）
    public static func fire(_ options: ConfettiOptions = .default) {
        if defaultInstance == nil {
            defaultInstance = SwiftConfetti.create()
        }
        defaultInstance?.fire(options)
    }

    /// リセット
    public static func reset() {
        defaultInstance?.reset()
    }

    /// カスタムcanvasでインスタンス作成
    public static func create(canvas: NSView? = nil, options: CreateOptions = .default) -> SwiftConfetti {
        return SwiftConfetti(canvas: canvas, globalOpts: options)
    }

    private init(canvas: NSView? = nil, globalOpts: CreateOptions = .default) {
        // 先に全てのプロパティを初期化
        self.allowResize = globalOpts.resize
        self.globalDisableForReducedMotion = globalOpts.disableForReducedMotion
        self.preferLessMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        // canvasがnilの場合は自動作成
        if let providedCanvas = canvas {
            self.canvas = providedCanvas
            self.isLibCanvas = false
        } else {
            // フルスクリーンの透明なcanvasを自動作成
            let autoCanvas = NSView()
            autoCanvas.wantsLayer = true
            autoCanvas.layer?.backgroundColor = NSColor.clear.cgColor

            // フルスクリーンサイズに設定
            if let screen = NSScreen.main {
                autoCanvas.frame = screen.frame
            } else {
                autoCanvas.frame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
            }

            self.canvas = autoCanvas
            self.isLibCanvas = true
            print("📋 Auto-created fullscreen canvas for confetti")
        }

        // 必ずrendererを作成（canvasは必ず存在する）
        self.renderer = ConfettiSpriteKitRenderer(view: self.canvas!)
        print("🚀 SpriteKit renderer initialized with GPU acceleration!")
    }

    /// パーティクルを発射（canvas-confettiのfire関数）
    public func fire(_ options: ConfettiOptions = .default) {
        print("🔥 SwiftConfetti.fire() called - v2.2 Queue-based fix")

        let disableForReducedMotion = globalDisableForReducedMotion || options.disableForReducedMotion

        // Reduced motionチェック
        if disableForReducedMotion && preferLessMotion {
            print("⚠️ Reduced motion is enabled, skipping animation")
            return
        }

        // canvasとrendererは必ず存在する（初期化時に作成済み）
        guard let targetCanvas = canvas, let renderer = renderer else {
            print("❌ Unexpected error: canvas or renderer is nil")
            return
        }

        print("📏 Canvas bounds: \(targetCanvas.bounds)")

        let size = CGSize(width: targetCanvas.bounds.width, height: targetCanvas.bounds.height)

        // パーティクル生成
        let particles = createParticles(options: options, size: size)
        print("🎯 Created \(particles.count) particles")

        // アニメーション実行
        if let animationObj = animationObj {
            // 既存のアニメーションに追加
            print("➕ Adding particles to existing animation")
            animationObj.addParticles(particles)
        } else {
            // 新規アニメーション開始
            print("🎬 Starting new animation")
            animationObj = ConfettiAnimation(particles: particles, size: size, renderer: renderer)

            // アニメーション開始（非ブロッキング）
            animationObj?.start { [weak self] in
                Task { @MainActor in
                    print("🏁 Animation completed")
                    self?.onAnimationComplete()
                }
            }
        }
    }

    /// アニメーションをリセット
    public func reset() {
        animationObj?.reset()
        animationObj = nil
    }


    // MARK: - Private Methods

    private func createDefaultCanvas() -> NSView {
        let canvas = NSView()
        canvas.wantsLayer = true
        canvas.layer?.backgroundColor = NSColor.clear.cgColor

        // フルスクリーンサイズに設定
        if let screen = NSScreen.main {
            canvas.frame = screen.frame
        } else {
            // フォールバック
            canvas.frame = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        }

        return canvas
    }

    private func createCanvas(zIndex: Int) -> NSView {
        let canvas = NSView()
        canvas.wantsLayer = true
        canvas.layer?.zPosition = CGFloat(zIndex)
        canvas.layer?.backgroundColor = NSColor.clear.cgColor

        // フルスクリーンサイズに設定
        if let screen = NSScreen.main {
            canvas.frame = screen.frame
        }

        return canvas
    }

    private func createParticles(options: ConfettiOptions, size: CGSize) -> [Particle] {
        var particles: [Particle] = []
        let colors = colorsToRgb(options.colors)

        let startX = size.width * options.origin.x
        let startY = size.height * options.origin.y

        for i in 0..<options.particleCount {
            let particle = Particle(
                x: startX,
                y: startY,
                angle: options.angle,
                spread: options.spread,
                startVelocity: options.startVelocity,
                color: colors[i % colors.count],
                shape: options.shapes[randomInt(min: 0, max: options.shapes.count)],
                ticks: options.ticks,
                decay: options.decay,
                gravity: options.gravity,
                drift: options.drift,
                scalar: options.scalar,
                flat: options.flat
            )
            particles.append(particle)
        }

        return particles
    }

    private func onAnimationComplete() {
        print("🏁 onAnimationComplete called - Current animationObj: \(animationObj != nil)")
        // アニメーションオブジェクトは維持（常に再利用）
        print("♻️ Keeping animation object for instant reuse")
    }
}

// MARK: - Configuration Options

public struct CreateOptions: Sendable {
    public let resize: Bool
    public let useWorker: Bool // Swift版では未実装（将来的にGCD対応予定）
    public let disableForReducedMotion: Bool

    public init(
        resize: Bool = true,
        useWorker: Bool = false,
        disableForReducedMotion: Bool = false
    ) {
        self.resize = resize
        self.useWorker = useWorker
        self.disableForReducedMotion = disableForReducedMotion
    }

    public static let `default` = CreateOptions()
}

// MARK: - SwiftUI Integration

public struct ConfettiModifier: ViewModifier {
    @Binding var trigger: Bool
    let options: ConfettiOptions

    public init(trigger: Binding<Bool>, options: ConfettiOptions = .default) {
        self._trigger = trigger
        self.options = options
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    Task { @MainActor in
                        await SwiftConfetti.fire(options)
                        trigger = false
                    }
                }
            }
    }
}

public extension View {
    /// SwiftUIビューに紙吹雪エフェクトを追加
    func confetti(trigger: Binding<Bool>, options: ConfettiOptions = .default) -> some View {
        self.modifier(ConfettiModifier(trigger: trigger, options: options))
    }
}

// MARK: - Shape Helpers (canvas-confetti互換)

public extension SwiftConfetti {
    /// パスから形状を生成（canvas-confettiのshapeFromPath相当）
    static func shapeFromPath(_ pathData: String, matrix: [Double]? = nil) -> ConfettiShape {
        return .path(pathData, matrix: matrix)
    }

    /// テキストから形状を生成（canvas-confettiのshapeFromText相当）
    static func shapeFromText(
        _ text: String,
        scalar: Double? = nil,
        fontFamily: String? = nil,
        color: String? = nil
    ) -> ConfettiShape {
        return .text(text, scalar: scalar, fontFamily: fontFamily, color: color)
    }
}

// MARK: - Convenience Extensions

public extension SwiftConfetti {
    /// プリセット: 爆発エフェクト
    static func explode(particleCount: Int = 150, spread: Double = 180) async {
        let options = ConfettiOptions(
            particleCount: particleCount,
            spread: spread,
            startVelocity: 30,
            gravity: 0.5
        )
        await fire(options)
    }

    /// プリセット: 雪エフェクト
    static func snow(particleCount: Int = 200) async {
        let options = ConfettiOptions(
            particleCount: particleCount,
            angle: 270,
            spread: 180,
            startVelocity: 5,
            gravity: 0.3,
            drift: 0.5,
            colors: ["#FFFFFF"],
            shapes: [.circle]
        )
        await fire(options)
    }

    /// プリセット: ハートエフェクト
    static func hearts(particleCount: Int = 50) async {
        let options = ConfettiOptions(
            particleCount: particleCount,
            colors: ["#FF0000", "#FF69B4", "#FFB6C1"],
            shapes: [.text("❤️", scalar: 2, fontFamily: nil, color: nil)]
        )
        await fire(options)
    }
}