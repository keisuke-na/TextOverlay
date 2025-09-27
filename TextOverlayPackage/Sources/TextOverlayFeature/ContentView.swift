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

    init() {
        httpServer.delegate = self
        httpServer.start()

        // 起動成功メッセージとバージョン情報
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.addComment("✅ Server ready on port 8080")
            self?.addComment("📌 Version: 2.1 - Queue-based Confetti System")
            self?.addComment("🔧 Fixed: Consecutive 888 triggers now work properly")
        }
    }

    private func calculateTextWidth(_ text: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 32, weight: .bold)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
    }

    func addComment(_ text: String) {
        print("📥 addComment called with: \"\(text)\"")

        // "8"が3回以上連続しているかチェック
        if text.contains("888") {
            print("🎊 888 detected! Posting TriggerConfetti notification")
            // 毎回即座に紙吹雪を発射（クールダウンなし）
            NotificationCenter.default.post(name: Notification.Name("TriggerConfetti"), object: nil)
            print("📮 TriggerConfetti notification posted")
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
    @State private var animationProgress: [UUID: Bool] = [:]
    @StateObject private var commentManager = CommentManager()

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

                // 独立ウィンドウで紙吹雪を初期化（一度だけ）
                ConfettiWindowInitializer()

                ForEach(commentManager.comments) { comment in
                    Text(comment.text)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3, x: 2, y: 2)
                        .position(
                            x: animationProgress[comment.id] == true
                                ? -(comment.textWidth + 50)
                                : geometry.size.width + 200,
                            y: comment.yPosition
                        )
                        .animation(
                            Animation.linear(duration: comment.duration)
                                .delay(comment.delay),
                            value: animationProgress[comment.id]
                        )
                        .onAppear {
                            // 初期位置を設定してからアニメーション開始
                            if animationProgress[comment.id] == nil {
                                animationProgress[comment.id] = false
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                animationProgress[comment.id] = true
                            }

                            // アニメーション完了後にコメントを削除
                            DispatchQueue.main.asyncAfter(deadline: .now() + comment.duration + comment.delay) {
                                commentManager.comments.removeAll { $0.id == comment.id }
                                animationProgress.removeValue(forKey: comment.id)
                            }
                        }
                }
            }
        }
        .background(Color.clear)
    }

    public init() {}
}
