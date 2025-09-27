import SwiftUI
import AppKit
import SwiftConfetti

/// 独立したウィンドウで紙吹雪を表示
@MainActor
class ConfettiWindowController {
    private var confettiWindow: NSWindow?
    private var confettiInstance: SwiftConfetti?

    static let shared = ConfettiWindowController()

    private init() {
        setupWindow()
        setupNotificationObserver()
    }

    private func setupWindow() {
        // 透明なオーバーレイウィンドウを作成
        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // ウィンドウを透明に設定
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false

        // 最前面に表示
        window.level = .screenSaver

        // クリックスルー（マウスイベントを下のウィンドウに通す）
        window.ignoresMouseEvents = true

        // ウィンドウを表示
        window.makeKeyAndOrderFront(nil)

        // 紙吹雪用のビューを作成
        let confettiView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        confettiView.wantsLayer = true
        confettiView.layer?.backgroundColor = NSColor.clear.cgColor

        window.contentView = confettiView

        // SwiftConfettiインスタンスを作成
        confettiInstance = SwiftConfetti.create(canvas: confettiView)

        self.confettiWindow = window

        print("🪟 Confetti window created - Completely independent layer")
    }

    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(triggerConfetti),
            name: Notification.Name("TriggerConfetti"),
            object: nil
        )
    }

    @objc private func triggerConfetti() {
        print("🎆 Independent window: Firing confetti immediately!")

        // ランダムな設定で即座に発射
        let options = ConfettiOptions(
            particleCount: Int.random(in: 50...100),
            angle: Double.random(in: 55...125),
            spread: Double.random(in: 50...70),
            startVelocity: 45,
            decay: 0.9,
            gravity: 1,
            origin: .init(
                x: Double.random(in: 0.1...0.9),
                y: Double.random(in: 0.4...0.8)
            ),
            colors: [
                "#26ccff", "#a25afd", "#ff5e7e",
                "#88ff5a", "#fcff42", "#ffa62d", "#ff36ff"
            ]
        )

        confettiInstance?.fire(options)
    }

    func start() {
        // 初期化時に自動的に開始
        print("🚀 Confetti window controller started")
    }
}

/// ContentViewで使用するための初期化View
public struct ConfettiWindowInitializer: View {
    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                ConfettiWindowController.shared.start()
            }
    }
}