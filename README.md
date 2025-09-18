# TextOverlay

<div align="center">
  <img src="TextOverlay/Assets.xcassets/AppIcon.appiconset/icon.png" width="128" height="128" alt="TextOverlay Icon">
  <h3>画面上にニコニコ動画風のコメントを流すシンプルなmacOSアプリ</h3>
</div>

## 概要

TextOverlayは、macOSの画面全体に透明なオーバーレイを表示し、POSTされたテキストをニコニコ動画のようなスタイルで右から左へ流すアプリケーションです。

起動すると「✅ Server ready on port 8080」というメッセージが画面上を流れ、HTTPサーバーが起動したことを通知します。

## 特徴

- 🪟 画面全体に透明なオーバーレイウィンドウ
- 🌐 ポート8080でHTTPサーバーが自動起動
- 💬 POSTされたテキストをニコニコ動画風に表示
- 🎯 マウスクリックを透過（邪魔にならない）
- ⚡ CORS対応でWebアプリから直接送信可能

## システム要件

- macOS 15.4以降
- Xcode 16.0以降（ビルドする場合）

## インストール方法

### ソースからビルド

1. リポジトリをクローン
```bash
git clone https://github.com/yourusername/TextOverlay.git
cd TextOverlay
```

2. Xcodeでワークスペースを開く
```bash
open TextOverlay.xcworkspace
```

3. ビルドして実行（Cmd + R）

## 使い方

1. アプリを起動すると、画面上に「✅ Server ready on port 8080」が流れます

2. 別のターミナルやアプリケーションから、以下のようにテキストをPOST

```bash
curl -X POST http://localhost:8080/message \
  -H "Content-Type: application/json" \
  -d '{"text":"こんにちは！"}'
```

3. 送信されたテキストが画面上を右から左へ流れます

### JavaScriptからの送信例

```javascript
fetch('http://localhost:8080/message', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ text: 'Hello from Web!' })
});
```

## API仕様

### POST /message

テキストメッセージを画面に表示

**リクエスト:**
```json
{
  "text": "表示したいテキスト"
}
```

**レスポンス:**
- 成功: `200 OK`
- 失敗: `400 Bad Request`

CORS対応のため、任意のオリジンからアクセス可能です。

## 技術仕様

- SwiftUI + AppKitで実装
- CFSocketを使用したHTTPサーバー
- 透明・クリックスルーなフローティングウィンドウ
- 最大50コメントまでメモリ管理

## 開発者向け

詳細な開発ドキュメントは [DEVELOPMENT.md](DEVELOPMENT.md) を参照してください。

## ライセンス

MIT

## 作者

keisuke-na