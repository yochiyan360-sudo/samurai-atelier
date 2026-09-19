# サムライのアトリエ / Samurai Atelier

![Samurai Atelier garden](dist/assets/samurai-garden-intro.png)

サムライをテーマにしたゲーム、ビジュアル作品、デジタルガジェットを集めた個人ポートフォリオサイトです。日本語と英語の両方に対応しています。

A bilingual personal portfolio featuring samurai-themed games, visual artwork, and digital gadgets.

## Live site

- [サムライのアトリエ](https://yochiyan360-sudo.github.io/samurai-atelier/)
- [English version](https://yochiyan360-sudo.github.io/samurai-atelier/en/)

## Featured projects

- **サムライ-斬 / Samurai-Zan** — ローマ字入力で斬撃を弾き返すタイピング剣戟ゲーム
- **サムライ・ソリティア / Samurai Solitaire** — 侍の世界観で遊ぶブラウザ版ソリティア
- **デジタル時計ウィジェット / Digital Clock Widget** — Windows向けの一枚ファイル時計
- **作品ギャラリー / Art Gallery** — 雨、刀、城下町を題材にしたサムライ作品

## Site features

- 庭園の全画面オープニングと連続テキストアニメーション
- 日本語・英語の切り替え
- レスポンシブ表示
- 画像ギャラリー
- 実際に動くデジタル時計プレビュー
- 外部ゲームとXアカウントへのリンク

## Project structure

```text
dist/
├─ index.html          # 日本語版 / Japanese
├─ en/index.html       # English
├─ styles.css
├─ site.js
└─ assets/
```

このサイトはビルド不要の静的HTMLです。ローカルで確認する場合は、リポジトリのルートから次を実行してください。

```bash
python -m http.server 8000 --directory dist
```

ブラウザで `http://localhost:8000/` を開きます。

## GitHub Pages

`main` ブランチへの更新時に、`.github/workflows/pages.yml` が `dist` フォルダをGitHub Pagesへ公開します。リポジトリ作成後、GitHubの **Settings → Pages → Source** を **GitHub Actions** に設定してください。

## Contact

- X: [@yochiyan360](https://x.com/yochiyan360)

## Rights

© 2026 yochiyan360. All rights reserved. ソースコード、画像、ゲーム素材の再利用・再配布については、事前に作者へお問い合わせください。
