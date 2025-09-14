import SwiftUI

struct Comment: Identifiable {
    let id = UUID()
    let text: String
    let yPosition: CGFloat
    let duration: Double
    let delay: Double
}

public struct ContentView: View {
    @State private var animationProgress: [UUID: Bool] = [:]

    let comments = [
        Comment(text: "すごい！！", yPosition: 100, duration: 8, delay: 0),
        Comment(text: "キタ━━━(ﾟ∀ﾟ)━━━!!", yPosition: 200, duration: 10, delay: 1),
        Comment(text: "888888888", yPosition: 300, duration: 7, delay: 2),
        Comment(text: "わこつ〜", yPosition: 400, duration: 9, delay: 3),
        Comment(text: "神回確定", yPosition: 150, duration: 11, delay: 4),
        Comment(text: "ｷﾀｺﾚ", yPosition: 350, duration: 8, delay: 5),
        Comment(text: "うぽつです", yPosition: 250, duration: 10, delay: 6),
    ]

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

                ForEach(comments) { comment in
                    Text(comment.text)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3, x: 2, y: 2)
                        .position(
                            x: animationProgress[comment.id] ?? false
                                ? -200
                                : geometry.size.width + 200,
                            y: comment.yPosition
                        )
                        .animation(
                            Animation.linear(duration: comment.duration)
                                .delay(comment.delay)
                                .repeatForever(autoreverses: false),
                            value: animationProgress[comment.id]
                        )
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                animationProgress[comment.id] = true
                            }
                        }
                }
            }
        }
        .background(Color.clear)
    }

    public init() {}
}
