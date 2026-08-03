<div align="center">

<img src="docs/images/icon.png" width="112" alt="Delayed Cmd+Q">

# Delayed Cmd+Q

**⌘Q の押し間違いで作業を失わないために。**

⌘Q は軽く押すのではなく、押し続けます。押している間にリングが時計回りに満ちていき、<br>
途中で離せば何も起きません。

[![Platform](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Release](https://img.shields.io/github/v/release/mnjn00/DelayedCmdQ?sort=semver&display_name=tag&color=brightgreen)](https://github.com/mnjn00/DelayedCmdQ/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/mnjn00/DelayedCmdQ/total?label=downloads&color=orange)](https://github.com/mnjn00/DelayedCmdQ/releases)

[English](README.md) · [한국어](README.ko.md) · **日本語** · [简体中文](README.zh-Hans.md)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/demo-dark.gif">
  <img src="docs/images/demo-light.gif" width="440" alt="⌘Q を押している間に時計回りに満ちるリング">
</picture>

</div>

---

## なぜ必要か

⌘Q は ⌘Tab のすぐ下、⌘W の隣にあります。うっかり押した瞬間にアプリは終了し、保存して
いなかったものも一緒に消えます。

Delayed Cmd+Q は、どのアプリにも届く前にこのショートカットを横取りします。終了するには
意図的に押し続ける必要があり、あとどれだけ保てばよいかをリングが正確に示します。途中で
離せばキー入力はそのまま破棄され、アプリは押されたことすら知りません。

## 特長

- **押し続けて終了** — 自分で決めた時間だけ ⌘Q を押し続ける必要があります
- **ミニマルな HUD** — 12 時の位置から時計回りに満ちる、輪郭だけのリング
- **遅延時間の調整** — 0.3〜5.0 秒。設定画面でそのままプレビューできます
- **連続終了の選択** — 押し続けて次のアプリへ進むか、最初の 1 つで止めるか
- **レイアウト対応** — AZERTY や QWERTZ、日本語・韓国語の入力中でも正しく動作します
- **邪魔をしない** — メニューバーのみ、Dock アイコンなし、いつでも一時停止できます
- **他のショートカットはそのまま** — ⌘⇧Q（ログアウト）と ⌘⌥Q は横取りしません

<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/ring-dark.png">
  <img src="docs/images/ring-light.png" width="620" alt="0、25、50、75、100 パーセントの状態のリング">
</picture>
</div>

## インストール

### ダウンロード

1. [最新リリース](https://github.com/mnjn00/DelayedCmdQ/releases/latest)から **`DelayedCmdQ.zip`** を入手します。
2. 展開して `DelayedCmdQ.app` を `/Applications` に移動します。
3. ダウンロードの隔離属性を取り除きます:

```bash
xattr -dr com.apple.quarantine /Applications/DelayedCmdQ.app
```

> [!NOTE]
> 手順 3 が必要なのは、このアプリが公証（notarize）ではなく ad-hoc 署名を使っているため
> です。有料の Apple Developer アカウントを持っていません。省略すると macOS はアプリが
> 壊れていると表示します。このコマンドを実行したくない場合は、
> [ソースからビルド](#ソースからビルド)しても結果は同じです。

### ソースからビルド

macOS 14 以降と Xcode 26（Swift 6）が必要です。

```bash
git clone https://github.com/mnjn00/DelayedCmdQ.git
cd DelayedCmdQ
./Scripts/build-app.sh
cp -R build/DelayedCmdQ.app /Applications/
```

`UNIVERSAL=1` を付けると Intel + Apple Silicon のユニバーサルバイナリになります。

## 初回起動

⌘Q を横取りするには**アクセシビリティ**の許可が必要です。

1. アプリを起動すると、許可を求めて設定ウインドウが開きます。
2. **システム設定 → プライバシーとセキュリティ → アクセシビリティ**を開きます。
3. **Delayed Cmd+Q** を有効にします。

許可した時点で動作を開始し、再起動は不要です。アプリはメニューバーにのみ常駐し、Dock
アイコンはありません。

> [!IMPORTANT]
> ソースから再ビルドすると ad-hoc 署名が変わり、macOS が許可をリセットします。
> アクセシビリティの一覧で古い項目を `−` で削除し、新しいビルドを追加してください。

## 設定

メニューバーのアイコンから開くか、<kbd>⌘</kbd><kbd>,</kbd> を押してください。

| 項目 | 説明 | 既定値 |
| --- | --- | --- |
| **遅延時間** | ⌘Q を押し続ける必要のある時間 | `1.0 秒` |
| **連続終了を許可** | 押し続けている間、次のアプリも続けて終了 | オフ |
| **一時停止** | ⌘Q を本来の動作に戻す | オフ |
| **ログイン時に起動** | ログイン項目として登録 | オフ |
| **アプリアイコンを表示** | 終了対象アプリのアイコンをリング中央に表示 | オン |

設定ウインドウ上部のリングをクリックすると、現在の遅延時間でプレビューできます。

### 連続終了

**オフ**（既定）の場合、最初のアプリが終了したあとは、どれだけ押し続けても何も起きません。

**オン**の場合、フォーカスが実際に別のアプリへ移るのを待ってから、そのアプリを対象に
リングを最初から満たし直します。終了のたびに最後まで押し続ける必要があるため、一度の
キー入力で複数のアプリがまとめて消えることはありません。3 秒以内にフォーカスが移らない
場合 — 保存確認のダイアログが出たときなど — 連鎖はそこで止まります。

## 内部構造

```
Sources/DelayedCmdQKit/
  App/         アプリデリゲート、メニューバー、メインメニュー、設定ウインドウ
  Core/        イベントタップ、ホールド状態機械、カウントダウン、権限、キーボードレイアウト
  Overlay/     オーバーレイパネルと進捗リングのビュー
  Settings/    環境設定モデルと設定画面
```

動作の中心は次の 3 つです。

- **`QuitKeyMonitor`** はセッションのイベントタップに `.defaultTap` モードで接続し、⌘Q の
  キーダウンをそのまま破棄します。最前面のアプリはショートカットが押されたこと自体を
  知らず、ホールドが完了した場合にのみ `QuitCoordinator` が明示的に終了を要求します。
- **`QuitHoldMachine`** はホールドのすべての状態遷移を持つ純粋な値型です。イベントではなく
  意味単位の入力を受け取るため、アクセシビリティ権限や擬似 `CGEvent` なしにライフサイクル
  全体をテストできます。
- **`KeyboardLayout`** は `UCKeyTranslate` を使い、現在の ASCII 対応レイアウトから Q の
  キーコードを解決します。macOS 自身がコマンドショートカットに用いる基準と同じなので、
  Q が QWERTY と異なる位置にある環境でも正確です。

### 開発

```bash
swift build     # コンパイル
swift test      # テストを実行
```

イベントタップとオーバーレイはシステム権限と画面を必要とするため、ユニットテストの対象外
です。ホールド状態機械、ショートカットの照合、遅延時間のポリシー、設定の永続化はすべて
テストで覆われています。

## 謝辞

このアイデアを macOS で切り拓いた [qblocker](https://github.com/steve228uk/qblocker) に
着想を得ています。

## ライセンス

[MIT](LICENSE) © mnjn00
