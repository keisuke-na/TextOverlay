import Foundation
import AppKit
import QuartzCore

/// canvas-confettiのrafを移植（requestAnimationFrame相当）
@MainActor
public class AnimationEngine {
    private var displayLink: Any? // macOS 14+ではCADisplayLink
    private var animationCallback: (() -> Void)?
    private var lastFrameTime: TimeInterval = 0
    private let targetFrameTime: TimeInterval = 1.0 / 60.0
    private weak var view: NSView?

    public init(view: NSView? = nil) {
        self.view = view
    }

    /// アニメーションフレームを開始
    @discardableResult
    public func frame(_ callback: @escaping () -> Void) -> AnimationEngine {
        self.animationCallback = callback

        if displayLink == nil {
            if #available(macOS 14.0, *), let view = view {
                // macOS 14以降: NSView.displayLinkを使用（VSyncと同期）
                let link = view.displayLink(target: self, selector: #selector(updateAnimation))
                link.add(to: RunLoop.current, forMode: .common)
                displayLink = link
            } else {
                // フォールバック: Timerを使用
                displayLink = Timer.scheduledTimer(withTimeInterval: targetFrameTime, repeats: true) { [weak self] _ in
                    Task { @MainActor in
                        self?.updateAnimation()
                    }
                }
            }
        }

        return self
    }

    /// アニメーションをキャンセル
    public func cancel() {
        if #available(macOS 14.0, *) {
            if let link = displayLink as? CADisplayLink {
                link.invalidate()
            }
        } else {
            if let timer = displayLink as? Timer {
                timer.invalidate()
            }
        }
        displayLink = nil
        animationCallback = nil
    }

    @objc private func updateAnimation() {
        let currentTime = CACurrentMediaTime()

        // フレームレート制限（canvas-confettiと同じ60fps）
        if lastFrameTime == 0 || currentTime - lastFrameTime >= targetFrameTime {
            lastFrameTime = currentTime
            animationCallback?()
        }
    }
}

/// アニメーション制御クラス
@MainActor
public class ConfettiAnimation {
    private var particles: [Particle]
    private let size: CGSize
    private let renderer: ConfettiRenderer
    private var animationEngine: AnimationEngine?
    private var completion: (() -> Void)?
    private var isAnimating: Bool = false
    private var frameCount = 0
    private var idleFrameCount = 0  // パーティクルがない時の待機フレーム数
    private var isIdle: Bool = false  // アイドル状態のフラグ

    public init(particles: [Particle], size: CGSize, renderer: ConfettiRenderer) {
        self.particles = particles
        self.size = size
        self.renderer = renderer
    }

    /// アニメーションを開始（非ブロッキング）
    @MainActor
    public func start(completion: @escaping () -> Void) {
        guard !isAnimating else {
            print("⚠️ Animation already running")
            return
        }

        isAnimating = true
        self.completion = completion

        // レンダラーからビューを取得してAnimationEngineに渡す
        let view: NSView?
        if let coreGraphicsRenderer = renderer as? ConfettiCoreGraphicsRenderer {
            view = coreGraphicsRenderer.getView()
        } else if let bitmapRenderer = renderer as? ConfettiBitmapRenderer {
            view = bitmapRenderer.getView()
        } else {
            view = nil
        }

        animationEngine = AnimationEngine(view: view)
        animationEngine?.frame { [weak self] in
            self?.updateFrame { shouldContinue in
                if !shouldContinue {
                    self?.stop()
                }
            }
        }
    }

    /// フレーム更新
    @MainActor
    private func updateFrame(completion: @escaping (Bool) -> Void) {
        frameCount += 1
        _ = frameCount

        // canvas-confettiのanimate関数と同じロジック
        renderer.clear()

        // パーティクルを更新（生存しているものだけ残す）
        let beforeCount = particles.count
        particles = particles.filter { particle in
            return updateParticle(particle)
        }
        let afterCount = particles.count
        _ = beforeCount
        _ = afterCount

        // 描画
        for (index, particle) in particles.enumerated() {
            _ = index
            renderer.drawParticle(particle, size: size)
        }

        renderer.present()

        // アニメーション継続判定
        if particles.isEmpty {
            // パーティクルがなくなったら、少しだけ待機（5フレーム）
            if !isIdle {
                isIdle = true
                idleFrameCount = 0
            }
            idleFrameCount += 1
            if idleFrameCount < 5 {
                completion(true) // 少しだけ待機
            } else {
                completion(false) // 停止
            }
        } else {
            isIdle = false
            idleFrameCount = 0
            completion(true) // アニメーション継続
        }
    }

    /// パーティクルを追加（canvas-confettiのaddFettis相当）
    public func addParticles(_ newParticles: [Particle]) {
        particles.append(contentsOf: newParticles)

        // アイドル状態をリセット
        if isIdle {
            isIdle = false
            idleFrameCount = 0
        }

        // アニメーションが停止していたら再開
        if !isAnimating && !particles.isEmpty {
            start(completion: completion ?? {})
        }
    }

    /// アニメーションをリセット
    public func reset() {
        stop()
        particles.removeAll()
        renderer.clear()
    }

    /// アニメーションを停止
    private func stop() {
        isAnimating = false
        isIdle = false
        idleFrameCount = 0
        animationEngine?.cancel()
        animationEngine = nil
        completion?()
        completion = nil
    }
}

/// Promise相当の非同期処理ラッパー
public actor ConfettiPromise {
    private var continuation: CheckedContinuation<Void, Never>?

    public func promise() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    public func resolve() {
        continuation?.resume()
        continuation = nil
    }
}

/// Rendererプロトコル（実装は次のファイルで）
@MainActor
public protocol ConfettiRenderer {
    func clear()
    func drawParticle(_ particle: Particle, size: CGSize)
    func present()
}
