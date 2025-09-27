import SwiftUI
import AppKit

/// 独立したNSPanelウィンドウでコメントを表示
@MainActor
class CommentWindowController {
    private var commentWindow: NSPanel?
    private var hostingController: NSHostingController<CommentOverlayView>?

    static let shared = CommentWindowController()

    private init() {
        setupWindow()
    }

    private func setupWindow() {
        // 透明なオーバーレイパネルを作成
        let panel = NSPanel(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // パネルを透明に設定
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        // 最前面に表示（フルスクリーンより上）
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)))

        // 全てのSpaceで表示、フルスクリーンの上にも表示
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // クリックスルー（マウスイベントを下のウィンドウに通す）
        panel.ignoresMouseEvents = true

        // CommentOverlayViewをホスティング
        let contentView = CommentOverlayView()
        let hostingController = NSHostingController(rootView: contentView)
        panel.contentView = hostingController.view

        // パネルを表示
        panel.makeKeyAndOrderFront(nil)

        self.commentWindow = panel
        self.hostingController = hostingController
    }

    func start() {
        // 初期化時に自動的に開始
    }
}

/// CommentWindowで使用するビュー
public struct CommentOverlayView: View {
    @State private var animationProgress: [UUID: Bool] = [:]
    @StateObject private var commentManager = CommentManager.shared

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

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
}

/// ContentViewで使用するための初期化View
public struct CommentWindowInitializer: View {
    public var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                CommentWindowController.shared.start()
            }
    }
}