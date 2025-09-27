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
                // 各IDに対して紙吹雪を即座に発射（遅延なし）
                for id in newIDs {
                    let particleCount = Int.random(in: 50...100)
                    let angle = Double.random(in: 55...125)
                    let spread = Double.random(in: 50...70)
                    let originX = Double.random(in: 0.1...0.9)
                    let originY = Double.random(in: 0.4...0.8)

                    let options = ConfettiOptions(
                        particleCount: particleCount,
                        angle: angle,
                        spread: spread,
                        startVelocity: 100,
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
                        confetti.fire(options)
                        self.processedIDs.insert(id)
                    }
                }
        }
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        // SwiftConfettiインスタンスを作成（このビューを使用）
        context.coordinator.confetti = SwiftConfetti.create(canvas: view)

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // キューに新しいアイテムがあれば処理
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
                    confettiQueue.append(id)
                }
        }
    }
}

#Preview {
    ConfettiView(screenSize: CGSize(width: 800, height: 600))
}
