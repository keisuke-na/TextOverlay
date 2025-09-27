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

    }

    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(triggerConfetti),
            name: Notification.Name("TriggerConfetti"),
            object: nil
        )

        // NotificationCenter.default.addObserver(
        //     self,
        //     selector: #selector(triggerConfettiFirework),
        //     name: Notification.Name("TriggerConfettiFirework"),
        //     object: nil
        // )
    }

    @objc private func triggerConfetti() {
        Task { @MainActor in
            let burstCount = 4
            let interval: UInt64 = 250_000_000

            let colorSets = [
                ["#ff6b6b", "#ff5e7e", "#ff8787", "#e74c3c", "#ff6348", "#ff4757", "#ee5a24"],  // 赤系
                ["#ffeaa7", "#fdcb6e", "#f9ca24", "#f6e58d", "#ffcc00", "#ffa502", "#ffda79"],  // 黄色系
                ["#74b9ff", "#54a0ff", "#48dbfb", "#0abde3", "#006ba6", "#3498db", "#45b7d1"],  // 青系
                ["#a29bfe", "#6c5ce7", "#5f3dc4", "#9b59b6", "#8e44ad", "#be2edd", "#c56cf0"]   // 紫系
            ]

            // 今回の発射で使用する色セットをランダムに選択
            let selectedColorSet = colorSets.randomElement()!

            for index in 0..<burstCount {
                let xPositions = [0.125, 0.375, 0.625, 0.875]
                let angles = [45.0, 70.0, 110.0, 135.0]

                let xPosition = xPositions[index % 4]
                let angle = 90.0

                let options = ConfettiOptions(
                    particleCount: Int.random(in: 100...150),
                    angle: angle,
                    spread: Double.random(in: 50...70),
                    startVelocity: 150,
                    decay: 0.9,
                    gravity: 1,
                    origin: .init(
                        x: xPosition,
                        y: 1.05
                    ),
                    colors: selectedColorSet,
                    shapes: [.square],
                    scalar: 1.5
                )

                confettiInstance?.fire(options)

                if index < burstCount - 1 {
                    try? await Task.sleep(nanoseconds: interval)
                }
            }
        }
    }

    @objc private func triggerConfettiFirework() {
        Task { @MainActor in
            func makeFireworkOptions(
                particleCount: Int,
                startVelocity: Double,
                decay: Double,
                gravity: Double,
                ticks: Int,
                colors: [String],
                scalar: Double
            ) -> ConfettiOptions {
                ConfettiOptions(
                    particleCount: particleCount,
                    angle: 90,
                    spread: Double.random(in: 200...260),
                    startVelocity: startVelocity,
                    decay: decay,
                    gravity: gravity,
                    ticks: ticks,
                    origin: .init(
                        x: Double.random(in: 0.2...0.8),
                        y: Double.random(in: 0.15...0.3)
                    ),
                    colors: colors,
                    shapes: [.circle, .star],
                    scalar: scalar
                )
            }

            let bursts: [ConfettiOptions] = [
                makeFireworkOptions(
                    particleCount: 160,
                    startVelocity: 95,
                    decay: 0.97,
                    gravity: 0.9,
                    ticks: 400,
                    colors: [
                        "#ffffff", "#ffe066", "#ff6b6b",
                        "#845ef7", "#4dabf7"
                    ],
                    scalar: 2
                ),
                makeFireworkOptions(
                    particleCount: 180,
                    startVelocity: 100,
                    decay: 0.968,
                    gravity: 0.95,
                    ticks: 420,
                    colors: [
                        "#ffffff", "#ffd43b", "#ff8787",
                        "#7048e8", "#15aabf"
                    ],
                    scalar: 2
                ),
            ]

            for (index, options) in bursts.enumerated() {
                if index > 0 {
                    try? await Task.sleep(nanoseconds: 180_000_000)
                }
                confettiInstance?.fire(options)
            }
        }
    }

    func start() {
        // 初期化時に自動的に開始
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
