import SwiftUI
import SwiftConfetti
import AppKit

// MARK: - NSViewRepresentable for SwiftConfetti
struct ConfettiCanvasView: NSViewRepresentable {
    @Binding var confettiQueue: [UUID]
    let screenSize: CGSize

    @MainActor
    class Coordinator {
        var confetti: SwiftConfetti?
        var processedIDs: Set<UUID> = []
        var fireTimer: Timer?

        func processQueue(queue: [UUID]) {
            // 未処理のIDを取得
            let newIDs = queue.filter { !processedIDs.contains($0) }

            if !newIDs.isEmpty {
                print("🔄 ConfettiCanvasView v2.0: Processing \(newIDs.count) new confetti triggers")

                // 各IDに対して紙吹雪を即座に発射（遅延なし）
                for id in newIDs {
                    print("🎯 Processing confetti ID: \(id)")

                    // canvas-confetti準拠の設定
                    let particleCount = Int.random(in: 50...100)
                    let angle = Double.random(in: 55...125)
                    let spread = Double.random(in: 50...70)
                    let originX = Double.random(in: 0.1...0.9)
                    let originY = Double.random(in: 0.4...0.8)

                    print("📊 パーティクル設定 for ID \(id):")
                    print("  - particleCount: \(particleCount)")
                    print("  - angle: \(angle)")
                    print("  - spread: \(spread)")
                    print("  - origin: x:\(String(format: "%.2f", originX)), y:\(String(format: "%.2f", originY))")

                    let options = ConfettiOptions(
                        particleCount: particleCount,
                        angle: angle,
                        spread: spread,
                        startVelocity: 45,
                        decay: 0.9,
                        gravity: 1,
                        origin: .init(x: originX, y: originY),
                        colors: [
                            "#26ccff",
                            "#a25afd",
                            "#ff5e7e",
                            "#88ff5a",
                            "#fcff42",
                            "#ffa62d",
                            "#ff36ff"
                        ]
                    )

                    if let confetti = self.confetti {
                        print("📍 Calling fire() for ID: \(id)")
                        confetti.fire(options)
                        self.processedIDs.insert(id)
                        print("✅ Fire completed for ID: \(id)")
                    } else {
                        print("❌ ERROR: confetti instance is nil for ID: \(id)")
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        print("🎨 ConfettiCanvasView v2.0 (Queue-based): Creating NSView")
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        // SwiftConfettiインスタンスを作成（このビューを使用）
        context.coordinator.confetti = SwiftConfetti.create(canvas: view)
        print("✅ ConfettiCanvasView v2.0: SwiftConfetti instance created")
        print("🔧 Using queue-based trigger system to avoid SwiftUI batching")

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // キューに新しいアイテムがあれば処理
        print("🔍 updateNSView called - Queue has \(confettiQueue.count) items, Processed: \(context.coordinator.processedIDs.count)")
        context.coordinator.processQueue(queue: confettiQueue)
    }
}

// MARK: - SwiftConfetti統合View
struct ConfettiView: View {
    @State private var confettiQueue: [UUID] = []
    let screenSize: CGSize

    var body: some View {
        ZStack {
            // 紙吹雪を描画するキャンバス
            ConfettiCanvasView(confettiQueue: $confettiQueue, screenSize: screenSize)
                .allowsHitTesting(false)
                .frame(width: screenSize.width, height: screenSize.height)

            // 透明なビュー（通知を受信）
            Color.clear
                .allowsHitTesting(false)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TriggerConfetti"))) { notification in
                    let id = UUID()
                    print("🎯 ConfettiView: Notification受信！ID: \(id)")
                    print("📐 Screen size: \(screenSize)")
                    print("📦 Queue before: \(confettiQueue.count) items")
                    confettiQueue.append(id)
                    print("📦 Queue after: \(confettiQueue.count) items")
                }
        }
        .onAppear {
            print("👁 ConfettiView appeared with size: \(screenSize)")
        }
    }
}

#Preview {
    ConfettiView(screenSize: CGSize(width: 800, height: 600))
}