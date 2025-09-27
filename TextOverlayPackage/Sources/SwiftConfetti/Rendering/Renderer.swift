import Foundation
import AppKit
import QuartzCore

/// Core Graphics ベースのレンダラー
@MainActor
public class ConfettiCoreGraphicsRenderer: ConfettiRenderer {
    private weak var view: NSView?
    private var containerLayer: CALayer?
    private var particleLayers: [CALayer] = []

    public init(view: NSView) {
        self.view = view
        setupContainerLayer()
    }

    /// AnimationEngineで使用するためのビュー取得
    public func getView() -> NSView? {
        return view
    }

    private func setupContainerLayer() {
        guard let view = view else { return }

        let container = CALayer()
        container.frame = view.bounds
        container.backgroundColor = NSColor.clear.cgColor
        container.isOpaque = false

        view.layer = CALayer()
        view.wantsLayer = true
        view.layer?.addSublayer(container)

        self.containerLayer = container
    }

    public func clear() {
        particleLayers.forEach { $0.removeFromSuperlayer() }
        particleLayers.removeAll()
    }

    public func drawParticle(_ particle: Particle, size: CGSize) {
        guard let containerLayer = containerLayer else { return }

        // 既存のレイヤーを再利用するか新規作成
        let layer: CALayer
        if let existingLayer = particleLayers.first(where: { $0.name == String(particle.tick) }) {
            layer = existingLayer
        } else {
            layer = createParticleLayer(for: particle)
            layer.name = String(particle.tick)
            containerLayer.addSublayer(layer)
            particleLayers.append(layer)
        }

        // canvas-confettiと同じ座標系（Y軸反転）
        let x = particle.x
        let y = size.height - particle.y // Y軸を反転

        // レイヤーの位置と変形を更新
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        layer.position = CGPoint(x: x, y: y)
        layer.opacity = Float(particle.opacity)

        // 回転と傾きの適用
        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, particle.rotation, 0, 0, 1)

        // wobble効果のためのスケール変換
        let scaleX = abs(particle.x2 - particle.x1) * 0.1
        let scaleY = abs(particle.y2 - particle.y1) * 0.1
        transform = CATransform3DScale(transform, scaleX, scaleY, 1)

        layer.transform = transform

        CATransaction.commit()
    }

    public func present() {
        // CALayerは自動的に描画されるため、特別な処理は不要
        // 必要に応じてlayoutIfNeededを呼ぶ
        view?.needsDisplay = true
    }

    private func createParticleLayer(for particle: Particle) -> CALayer {
        let layer = CAShapeLayer()

        switch particle.shape {
        case .square:
            layer.path = createSquarePath(size: CGSize(width: 10 * particle.scalar, height: 6 * particle.scalar))
        case .circle:
            layer.path = createCirclePath(radius: 5 * particle.scalar)
        case .star:
            layer.path = createStarPath(outerRadius: 8 * particle.scalar, innerRadius: 4 * particle.scalar)
        default:
            layer.path = createSquarePath(size: CGSize(width: 10 * particle.scalar, height: 6 * particle.scalar))
        }

        layer.fillColor = particle.color.nsColor.cgColor
        layer.strokeColor = nil

        return layer
    }

    private func createSquarePath(size: CGSize) -> CGPath {
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
        return CGPath(rect: rect, transform: nil)
    }

    private func createCirclePath(radius: Double) -> CGPath {
        return CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2), transform: nil)
    }

    private func createStarPath(outerRadius: Double, innerRadius: Double) -> CGPath {
        // canvas-confettiと同じ星形パス生成
        let path = CGMutablePath()
        let spikes = 5
        let step = Double.pi / Double(spikes)
        var rot = Double.pi / 2 * 3

        for _ in 0..<spikes {
            var x = cos(rot) * outerRadius
            var y = sin(rot) * outerRadius
            if path.isEmpty {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            rot += step

            x = cos(rot) * innerRadius
            y = sin(rot) * innerRadius
            path.addLine(to: CGPoint(x: x, y: y))
            rot += step
        }

        path.closeSubpath()
        return path
    }
}

/// 高速描画用のビットマップレンダラー
@MainActor
public class ConfettiBitmapRenderer: ConfettiRenderer {
    private weak var view: NSView?
    private var bitmapContext: CGContext?
    private let scale: CGFloat
    private var presentCount = 0

    public init(view: NSView) {
        self.view = view
        self.scale = view.window?.backingScaleFactor ?? 2.0
        setupBitmapContext()
    }

    /// AnimationEngineで使用するためのビュー取得
    public func getView() -> NSView? {
        return view
    }

    private func setupBitmapContext() {
        guard let view = view else { return }

        // ビューにレイヤーが必要
        view.wantsLayer = true
        if view.layer == nil {
            view.layer = CALayer()
        }

        let width = max(Int(view.bounds.width * scale), 100)
        let height = max(Int(view.bounds.height * scale), 100)

        print("🖼 Setting up bitmap context: \(width)x\(height), scale: \(scale)")

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        bitmapContext = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        bitmapContext?.scaleBy(x: scale, y: scale)
    }

    private func updateContextIfNeeded() {
        guard let view = view else { return }
        let currentWidth = Int(view.bounds.width * scale)
        let currentHeight = Int(view.bounds.height * scale)

        // コンテキストのサイズが変わったら再作成
        if currentWidth > 0 && currentHeight > 0 {
            if bitmapContext == nil ||
               bitmapContext?.width != currentWidth ||
               bitmapContext?.height != currentHeight {
                setupBitmapContext()
            }
        }
    }

    public func clear() {
        updateContextIfNeeded()
        guard let context = bitmapContext, let view = view else { return }
        context.clear(CGRect(origin: .zero, size: view.bounds.size))
    }

    public func drawParticle(_ particle: Particle, size: CGSize) {
        guard let context = bitmapContext else {
            print("❌ No bitmap context for drawing particle")
            return
        }

        context.saveGState()

        // 透明度設定
        context.setAlpha(particle.opacity)

        // 色設定
        let color = particle.color.nsColor
        context.setFillColor(color.cgColor)

        // 座標変換（wobbleポジションを使用）
        context.translateBy(x: particle.wobbleX, y: size.height - particle.wobbleY)
        context.rotate(by: particle.rotation)

        // 形状描画
        switch particle.shape {
        case .square:
            drawSquare(in: context, particle: particle)
        case .circle:
            drawCircle(in: context, particle: particle)
        case .star:
            drawStar(in: context, particle: particle)
        default:
            drawSquare(in: context, particle: particle)
        }

        context.restoreGState()
    }

    public func present() {
        guard let context = bitmapContext,
              let cgImage = context.makeImage(),
              let view = view else {
            print("❌ Failed to present: context=\(bitmapContext != nil), view=\(view != nil)")
            return
        }

        presentCount += 1
        // 既にメインスレッドで実行されているため、直接設定
        view.layer?.contents = cgImage

        // 最初と10フレームごとにログ
        if presentCount == 1 || presentCount % 10 == 0 {
            print("✅ Presented frame \(presentCount)")
        }
    }

    private func drawSquare(in context: CGContext, particle: Particle) {
        let width = particle.width
        let height = particle.height
        context.fill(CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
    }

    private func drawCircle(in context: CGContext, particle: Particle) {
        let width = particle.width * particle.ovalScalar
        let height = particle.height * particle.ovalScalar
        context.fillEllipse(in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))
    }

    private func drawStar(in context: CGContext, particle: Particle) {
        let outerRadius = 8 * particle.scalar
        let innerRadius = 4 * particle.scalar
        let spikes = 5
        let step = Double.pi / Double(spikes)
        var rot = Double.pi / 2 * 3

        context.beginPath()

        for i in 0..<spikes {
            var x = cos(rot) * outerRadius
            var y = sin(rot) * outerRadius

            if i == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
            rot += step

            x = cos(rot) * innerRadius
            y = sin(rot) * innerRadius
            context.addLine(to: CGPoint(x: x, y: y))
            rot += step
        }

        context.closePath()
        context.fillPath()
    }
}