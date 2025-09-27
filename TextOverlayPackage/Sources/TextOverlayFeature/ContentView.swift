import SwiftUI

struct Comment: Identifiable {
    let id = UUID()
    let text: String
    let yPosition: CGFloat
    let duration: Double
    let delay: Double
    let textWidth: CGFloat
}

@MainActor
class CommentManager: ObservableObject {
    @Published var comments: [Comment] = []
    private let httpServer = SimpleHTTPServer()

    static let shared = CommentManager()

    init() {
        httpServer.delegate = self
        httpServer.start()

        // 起動成功メッセージとバージョン情報
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.addComment("✅ Server ready on port 8080")
        }
    }

    private func calculateTextWidth(_ text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 32, weight: .bold)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
    }

    func addComment(_ text: String) {
        if text.contains("888") {
            NotificationCenter.default.post(name: Notification.Name("TriggerConfetti"), object: nil)
        }

        if text.contains("***") {
            // NotificationCenter.default.post(name: Notification.Name("TriggerConfettiFirework"), object: nil)
        }

        let textWidth = calculateTextWidth(text)
        let newComment = Comment(
            text: text,
            yPosition: CGFloat.random(in: 100...600),
            duration: Double.random(in: 8...12),
            delay: 0,
            textWidth: textWidth
        )
        comments.append(newComment)

        // メモリ管理
        if comments.count > 50 {
            comments.removeFirst()
        }
    }

}

public struct ContentView: View {
    public var body: some View {
        ZStack {
            Color.clear
                .frame(width: 1, height: 1)

            // 独立ウィンドウで紙吹雪を初期化（一度だけ）
            ConfettiWindowInitializer()

            // 独立ウィンドウでコメントを初期化（一度だけ）
            CommentWindowInitializer()
        }
    }

    public init() {
        // CommentManagerのシングルトンインスタンスが初期化される
        _ = CommentManager.shared
    }
}
