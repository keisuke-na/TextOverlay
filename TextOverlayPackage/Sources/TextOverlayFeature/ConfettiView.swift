import SwiftUI
import SpriteKit

// MARK: - ConfettiScene
class ConfettiScene: SKScene {
    private var screenSize: CGSize = .zero

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .clear

        // 物理世界の設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8) // 現実的な重力

        // シーンのアンカーポイントを左下に設定
        anchorPoint = CGPoint(x: 0, y: 0)
    }

    func triggerConfetti(screenWidth: CGFloat, screenHeight: CGFloat) {
        screenSize = CGSize(width: screenWidth, height: screenHeight)

        // canvas-confettiと同じ設定を実装
        // origin.y = 0.6 は画面の60%の高さから発射（SpriteKitでは下から40%）
        let centerX = screenWidth * 0.5
        let centerY = screenHeight * 0.4  // 画面の40%の高さ（canvas-confettiのy:0.6相当）

        // ランダムパラメータを生成（canvas-confettiのrandomInRange相当）
        let angle = CGFloat.random(in: 55...125)  // 55-125度のランダム
        let spread = CGFloat.random(in: 50...70)  // 50-70度のランダムな広がり
        let particleCount = Int.random(in: 50...100)  // 50-100個のランダムな粒子数

        // 1回のバーストで全粒子を生成（canvas-confetti準拠）
        createBurst(
            position: CGPoint(x: centerX, y: centerY),
            particleCount: particleCount,
            angle: angle,
            spread: spread,
            startVelocity: 45,  // canvas-confettiのデフォルト値
            decay: 0.9  // canvas-confettiのデフォルト値
        )
    }

    private func createBurst(
        position: CGPoint,
        particleCount: Int,
        angle: CGFloat = 90,  // デフォルト90度（真上）
        spread: CGFloat,
        startVelocity: CGFloat,
        decay: CGFloat,
        scalar: CGFloat = 1.0
    ) {
        for _ in 0..<particleCount {
            createConfettiParticle(
                at: position,
                angle: angle,
                spread: spread,
                velocity: startVelocity,
                decay: decay,
                scalar: scalar
            )
        }
    }

    private func createConfettiParticle(
        at position: CGPoint,
        angle: CGFloat,
        spread: CGFloat,
        velocity: CGFloat,
        decay: CGFloat,
        scalar: CGFloat
    ) {
        // 紙吹雪の形状を作成（長方形）
        // canvas-confettiの色配列を使用
        let colors: [NSColor] = [
            NSColor(red: 0.15, green: 0.8, blue: 1.0, alpha: 1.0),    // #26ccff
            NSColor(red: 0.635, green: 0.353, blue: 0.992, alpha: 1.0), // #a25afd
            NSColor(red: 1.0, green: 0.369, blue: 0.494, alpha: 1.0),  // #ff5e7e
            NSColor(red: 0.533, green: 1.0, blue: 0.353, alpha: 1.0),  // #88ff5a
            NSColor(red: 0.988, green: 1.0, blue: 0.259, alpha: 1.0),  // #fcff42
            NSColor(red: 1.0, green: 0.651, blue: 0.176, alpha: 1.0),  // #ffa62d
            NSColor(red: 1.0, green: 0.212, blue: 1.0, alpha: 1.0)     // #ff36ff
        ]
        let randomColor = colors.randomElement() ?? .red

        let confetti = SKSpriteNode(color: randomColor, size: CGSize(width: 10 * scalar, height: 6 * scalar))
        confetti.position = position

        // 物理ボディを設定
        confetti.physicsBody = SKPhysicsBody(rectangleOf: confetti.size)
        confetti.physicsBody?.affectedByGravity = true
        confetti.physicsBody?.linearDamping = 1.0 - decay // 空気抵抗
        confetti.physicsBody?.angularDamping = 0.8
        confetti.physicsBody?.density = 0.1 // 軽い素材

        // 発射角度と速度を計算（canvas-confetti準拠）
        let baseAngle = -angle * Double.pi / 180  // 角度をラジアンに変換
        let spreadRadians = spread * Double.pi / 180
        // canvas-confettiの式: -radAngle + ((0.5 * radSpread) - (Math.random() * radSpread))
        // これは -spread/2 から +spread/2 の範囲でランダム
        let angle2D = baseAngle + ((0.5 * spreadRadians) - (Double.random(in: 0...1) * spreadRadians))

        // 速度ベクトルを設定（爆発的なクラッカー演出）
        // 注意：SpriteKitのY軸は下が0なので、上向きはプラス
        let vx = CGFloat(cos(angle2D)) * velocity * 30.0  // 横方向の勢いを倍増
        let vy = CGFloat(abs(sin(angle2D))) * velocity * 35.0  // 上向きの爆発力を大幅増加
        confetti.physicsBody?.velocity = CGVector(dx: vx, dy: vy)

        // 回転を追加
        let angularVelocity = CGFloat.random(in: -10...10)
        confetti.physicsBody?.angularVelocity = angularVelocity

        // Z軸回転アニメーション（3D効果のシミュレーション）
        let wobbleAction = SKAction.sequence([
            SKAction.scaleX(to: 0.2, duration: 0.2),
            SKAction.scaleX(to: 1.0, duration: 0.2)
        ])
        let wobbleForever = SKAction.repeatForever(wobbleAction)
        confetti.run(wobbleForever)

        // フェードアウトと削除
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])
        confetti.run(fadeOut)

        addChild(confetti)
    }
}

// MARK: - SpriteKit View Wrapper
struct SpriteKitView: NSViewRepresentable {
    let screenSize: CGSize
    @State private var scene: ConfettiScene?

    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 60

        // GPU最適化設定
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true

        // シーンを作成
        let scene = ConfettiScene()
        scene.size = screenSize
        scene.scaleMode = .resizeFill

        view.presentScene(scene)

        // Coordinatorに保存
        context.coordinator.scene = scene

        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        if let scene = nsView.scene as? ConfettiScene {
            scene.size = screenSize
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var scene: ConfettiScene?

        init() {
            // NotificationCenterの監視
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(triggerConfetti),
                name: Notification.Name("TriggerConfetti"),
                object: nil
            )
        }

        @MainActor @objc func triggerConfetti() {
            Task { @MainActor in
                scene?.triggerConfetti(
                    screenWidth: scene?.size.width ?? 0,
                    screenHeight: scene?.size.height ?? 0
                )
            }
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - ConfettiView
struct ConfettiView: View {
    let screenSize: CGSize

    var body: some View {
        SpriteKitView(screenSize: screenSize)
            .allowsHitTesting(false)
    }
}