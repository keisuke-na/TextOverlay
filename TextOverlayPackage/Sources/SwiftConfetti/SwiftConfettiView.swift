import SwiftUI
import AppKit

/// SwiftUI用のSwiftConfettiビュー
public struct SwiftConfettiView: NSViewRepresentable {
    @Binding var trigger: Bool
    let options: ConfettiOptions
    private let confettiInstance: SwiftConfetti

    public init(trigger: Binding<Bool>, options: ConfettiOptions = .default) {
        self._trigger = trigger
        self.options = options
        self.confettiInstance = SwiftConfetti.create()
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        // Coordinatorに保存
        context.coordinator.view = view
        context.coordinator.confetti = SwiftConfetti.create(canvas: view)

        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        if trigger {
            Task { @MainActor in
                await context.coordinator.confetti?.fire(options)
                trigger = false
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {
        var view: NSView?
        var confetti: SwiftConfetti?
    }
}

/// SwiftConfettiのオーバーレイビュー
public struct SwiftConfettiOverlay: View {
    @State private var showConfetti = false
    private let notificationName: Notification.Name

    public init(notificationName: Notification.Name = Notification.Name("TriggerSwiftConfetti")) {
        self.notificationName = notificationName
    }

    public var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in
                triggerConfetti()
            }
    }

    private func triggerConfetti() {
        Task { @MainActor in
            await SwiftConfetti.fire()
        }
    }
}

/// デモ用のビュー
public struct SwiftConfettiDemoView: View {
    @State private var triggerDefault = false
    @State private var triggerSnow = false
    @State private var triggerHearts = false
    @State private var triggerExplode = false

    public init() {}

    public var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("SwiftConfetti Demo")
                    .font(.largeTitle)
                    .bold()

                Text("canvas-confetti Swift移植版")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Divider()
                    .padding(.vertical)

                VStack(spacing: 15) {
                    Button("🎉 デフォルト紙吹雪") {
                        Task { @MainActor in
                            await SwiftConfetti.fire()
                        }
                    }
                    .buttonStyle(DemoButtonStyle(color: .blue))

                    Button("❄️ 雪エフェクト") {
                        Task { @MainActor in
                            await SwiftConfetti.snow()
                        }
                    }
                    .buttonStyle(DemoButtonStyle(color: .cyan))

                    Button("❤️ ハートエフェクト") {
                        Task { @MainActor in
                            await SwiftConfetti.hearts()
                        }
                    }
                    .buttonStyle(DemoButtonStyle(color: .pink))

                    Button("💥 爆発エフェクト") {
                        Task { @MainActor in
                            await SwiftConfetti.explode()
                        }
                    }
                    .buttonStyle(DemoButtonStyle(color: .orange))

                    Button("🎨 カスタムエフェクト") {
                        Task { @MainActor in
                            let options = ConfettiOptions(
                                particleCount: 100,
                                angle: 45,
                                spread: 90,
                                startVelocity: 60,
                                decay: 0.8,
                                gravity: 1.5,
                                drift: 1.0,
                                origin: .init(x: 0.5, y: 0.6),
                                colors: ["#FF1493", "#00CED1", "#FFD700", "#32CD32"],
                                shapes: [.square, .circle, .star],
                                scalar: 1.2
                            )
                            await SwiftConfetti.fire(options)
                        }
                    }
                    .buttonStyle(DemoButtonStyle(color: .purple))

                    Divider()
                        .padding(.vertical)

                    HStack {
                        Button("リセット") {
                            SwiftConfetti.reset()
                        }
                        .buttonStyle(DemoButtonStyle(color: .gray))

                        Button("連続発射") {
                            Task { @MainActor in
                                for i in 0..<5 {
                                    let options = ConfettiOptions(
                                        particleCount: 50,
                                        origin: .init(x: Double(i) * 0.25, y: 0.6)
                                    )
                                    await SwiftConfetti.fire(options)
                                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
                                }
                            }
                        }
                        .buttonStyle(DemoButtonStyle(color: .green))
                    }
                }
            }
            .padding(40)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .frame(width: 400, height: 600)
    }
}

// デモボタンスタイル
struct DemoButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}