import Foundation
import AppKit
import SpriteKit

/// SpriteKitベースの高速レンダラー（GPU加速）
@MainActor
public class ConfettiSpriteKitRenderer: ConfettiRenderer {
    private weak var view: NSView?
    private var skView: SKView?
    private var scene: ConfettiSKScene?
    private var particleNodes: [Int: SKNode] = [:]  // tick IDとノードのマッピング

    public init(view: NSView) {
        self.view = view
        setupSpriteKit()
    }

    /// AnimationEngineで使用するためのビュー取得
    public func getView() -> NSView? {
        return view
    }

    private func setupSpriteKit() {
        guard let view = view else { return }

        // SKViewを作成
        let spriteView = SKView(frame: view.bounds)
        spriteView.allowsTransparency = true
        // SKViewはbackgroundColorではなく、シーンの背景色を使用

        // パフォーマンス設定
        spriteView.ignoresSiblingOrder = true  // 描画順序を最適化
        spriteView.shouldCullNonVisibleNodes = true  // 見えないノードをカル

        // デバッグ情報（必要に応じてコメントアウト）
        // spriteView.showsFPS = true
        // spriteView.showsNodeCount = true

        // シーンを作成
        let confettiScene = ConfettiSKScene(size: view.bounds.size)
        confettiScene.scaleMode = .resizeFill
        confettiScene.backgroundColor = .clear

        // シーンを表示
        spriteView.presentScene(confettiScene)

        // ビューに追加
        view.addSubview(spriteView)

        self.skView = spriteView
        self.scene = confettiScene

        print("🎮 SpriteKit renderer initialized - GPU acceleration enabled!")
    }

    public func clear() {
        // 全てのパーティクルノードを削除
        scene?.removeAllChildren()
        particleNodes.removeAll()
    }

    public func drawParticle(_ particle: Particle, size: CGSize) {
        guard let scene = scene else { return }

        // 既存のノードを再利用するか新規作成
        let node: SKNode
        if let existingNode = particleNodes[particle.tick] {
            node = existingNode
        } else {
            // 新しいパーティクルノードを作成
            node = createParticleNode(for: particle)
            particleNodes[particle.tick] = node
            scene.addChild(node)
        }

        // 位置と回転を更新
        node.position = CGPoint(x: particle.x, y: size.height - particle.y)  // Y座標を反転
        node.zRotation = CGFloat(particle.tiltAngle)

        // スケールを更新
        let scale = CGFloat(particle.scalar)
        node.xScale = scale
        node.yScale = particle.flat ? scale * 0.5 : scale

        // 不透明度を更新
        node.alpha = CGFloat(particle.opacity)

        // 寿命が尽きたら削除
        if particle.opacity <= 0 {
            node.removeFromParent()
            particleNodes.removeValue(forKey: particle.tick)
        }
    }

    public func present() {
        // SpriteKitは自動的にレンダリングするため、特別な処理は不要
        // ただし、必要に応じてシーンの更新を強制できる
        skView?.scene?.isPaused = false
    }

    private func createParticleNode(for particle: Particle) -> SKNode {
        switch particle.shape {
        case .square:
            return createSquareNode(particle: particle)
        case .circle:
            return createCircleNode(particle: particle)
        case .star:
            return createStarNode(particle: particle)
        default:
            // デフォルトは正方形
            return createSquareNode(particle: particle)
        }
    }

    private func createSquareNode(particle: Particle) -> SKSpriteNode {
        let node = SKSpriteNode(color: particle.color.nsColor, size: CGSize(width: 10, height: 10))

        // 物理ボディを追加（オプション - パフォーマンスのためコメントアウト可能）
        // node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        // node.physicsBody?.affectedByGravity = false  // 重力は手動計算済み

        return node
    }

    private func createCircleNode(particle: Particle) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 5)
        node.fillColor = particle.color.nsColor
        node.strokeColor = .clear

        return node
    }

    private func createStarNode(particle: Particle) -> SKShapeNode {
        // 星形のパスを作成
        let path = CGMutablePath()
        let outerRadius: CGFloat = 5
        let innerRadius: CGFloat = 2.5
        let spikes = 5
        let step = CGFloat.pi / CGFloat(spikes)
        var rot = CGFloat.pi / 2 * 3

        for i in 0..<spikes {
            var x = cos(rot) * outerRadius
            var y = sin(rot) * outerRadius
            if i == 0 {
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

        let node = SKShapeNode(path: path)
        node.fillColor = particle.color.nsColor
        node.strokeColor = .clear

        return node
    }
}

/// SpriteKitのシーンクラス
@MainActor
private class ConfettiSKScene: SKScene {

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // 背景を透明に
        backgroundColor = .clear

        // 物理演算は使わない（パーティクルの位置は既に計算済み）
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }

    override func update(_ currentTime: TimeInterval) {
        // 画面外のノードを自動削除（パフォーマンス最適化）
        enumerateChildNodes(withName: "*") { node, _ in
            if node.position.y < -100 ||
               node.position.x < -100 ||
               node.position.x > self.size.width + 100 {
                node.removeFromParent()
            }
        }
    }
}