import Foundation
import AppKit
import SpriteKit

/// SpriteKitベースの高速レンダラー（GPU加速）
@MainActor
public class ConfettiSpriteKitRenderer: ConfettiRenderer {
    private weak var view: NSView?
    private var skView: SKView?
    private var scene: ConfettiSKScene?
    private var particleNodes: [Int: SKNode] = [:]  // パーティクルIDとノードのマッピング
    private var staleParticleIDs: Set<Int> = []

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

        // パフォーマンス設定
        spriteView.ignoresSiblingOrder = true
        spriteView.shouldCullNonVisibleNodes = true

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
    }

    public func clear() {
        // 今フレームで更新されなかったノードを後で削除するためにマーク
        staleParticleIDs = Set(particleNodes.keys)
    }

    public func drawParticle(_ particle: Particle, size: CGSize) {
        guard let scene = scene else { return }

        // 今フレームで使用するIDをマーク
        staleParticleIDs.remove(particle.id)

        // 既存のノードを再利用するか新規作成
        let node: SKNode
        if let existingNode = particleNodes[particle.id] as? SKShapeNode {
            node = existingNode
            if particle.shape == .square {
                updateSquareNodePath(existingNode, particle: particle, canvasSize: size)
            }
        } else {
            node = createParticleNode(for: particle, canvasSize: size)
            particleNodes[particle.id] = node
            scene.addChild(node)
        }

        // SpriteKit座標系での位置を反映（下原点）
        node.position = CGPoint(x: particle.x, y: size.height - particle.y)

        // 不透明度を更新
        node.alpha = CGFloat(particle.opacity)

        // 寿命が尽きたら削除
        if particle.opacity <= 0 {
            node.removeFromParent()
            particleNodes.removeValue(forKey: particle.id)
        }
    }

    public func present() {
        // 今フレームで更新されなかったノードを削除
        for id in staleParticleIDs {
            if let node = particleNodes.removeValue(forKey: id) {
                node.removeFromParent()
            }
        }
        staleParticleIDs.removeAll()

        // SpriteKitは自動描画だが、明示的に再開
        skView?.scene?.isPaused = false
    }

    private func createParticleNode(for particle: Particle, canvasSize: CGSize) -> SKNode {
        switch particle.shape {
        case .square:
            return createSquareNode(particle: particle, canvasSize: canvasSize)
        case .circle:
            return createCircleNode(particle: particle)
        case .star:
            return createStarNode(particle: particle)
        default:
            return createSquareNode(particle: particle, canvasSize: canvasSize)
        }
    }

    private func createSquareNode(particle: Particle, canvasSize: CGSize) -> SKShapeNode {
        let path = createSquarePath(for: particle, canvasSize: canvasSize)
        let node = SKShapeNode(path: path)
        node.fillColor = particle.color.nsColor
        node.strokeColor = .clear
        return node
    }

    private func createSquarePath(for particle: Particle, canvasSize: CGSize) -> CGPath {
        let path = CGMutablePath()

        let baseX = particle.x
        let baseY = canvasSize.height - particle.y
        let wobbleX = particle.wobbleX
        let wobbleY = canvasSize.height - particle.wobbleY
        let x1 = particle.x1
        let y1 = canvasSize.height - particle.y1
        let x2 = particle.x2
        let y2 = canvasSize.height - particle.y2

        path.move(to: .zero)
        path.addLine(to: CGPoint(x: CGFloat(wobbleX - baseX), y: CGFloat(y1 - baseY)))
        path.addLine(to: CGPoint(x: CGFloat(x2 - baseX), y: CGFloat(y2 - baseY)))
        path.addLine(to: CGPoint(x: CGFloat(x1 - baseX), y: CGFloat(wobbleY - baseY)))
        path.closeSubpath()

        return path
    }

    private func updateSquareNodePath(_ node: SKShapeNode, particle: Particle, canvasSize: CGSize) {
        node.path = createSquarePath(for: particle, canvasSize: canvasSize)
        node.fillColor = particle.color.nsColor
    }

    private func createCircleNode(particle: Particle) -> SKShapeNode {
        let radius = CGFloat(5 * particle.scalar)
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = particle.color.nsColor
        node.strokeColor = .clear

        let wobbleAction = SKAction.sequence([
            SKAction.scaleX(to: 0.2, duration: 0.2),
            SKAction.scaleX(to: 1.0, duration: 0.2)
        ])
        node.run(SKAction.repeatForever(wobbleAction))

        return node
    }

    private func createStarNode(particle: Particle) -> SKShapeNode {
        let path = CGMutablePath()
        let outerRadius = CGFloat(5 * particle.scalar)
        let innerRadius = CGFloat(2.5 * particle.scalar)
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

        let wobbleAction = SKAction.sequence([
            SKAction.scaleX(to: 0.2, duration: 0.2),
            SKAction.scaleX(to: 1.0, duration: 0.2)
        ])
        node.run(SKAction.repeatForever(wobbleAction))

        return node
    }
}

/// SpriteKitのシーンクラス
@MainActor
private class ConfettiSKScene: SKScene {

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }

    override func update(_ currentTime: TimeInterval) {
        enumerateChildNodes(withName: "*") { node, _ in
            if node.position.y < -100 ||
               node.position.x < -100 ||
               node.position.x > self.size.width + 100 {
                node.removeFromParent()
            }
        }
    }
}
