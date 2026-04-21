# Dawnbreaker Design System

## アクセス方法

```dart
final c = context.appColorScheme;       // AppColorScheme
final tc = context.appTaskColorScheme;  // AppTaskColorScheme
```

ライト/ダークは `MediaQuery.platformBrightnessOf(context)` で自動切り替え。

---

## カラー

`AppColorScheme` — UI 全体のセマンティックカラー（`app_colors.dart`）  
`AppTaskColorScheme` — タスクのカラーラベル用。`base / soft / on` の3バリアント（`app_colors.dart`）


タスクカラーは `TaskColor` の extension でアクセスする。`appTaskColorScheme` を直接触らない。

```dart
taskColor.baseColor(context)  // ベース色（バー・アイコン背景等）
taskColor.softColor(context)  // ソフト色（チップ背景等）
taskColor.onColor(context)    // On色（base/soft 上のテキスト・アイコン）
```

---

## タイポグラフィ・ボーダー半径

`AppTextStyle` — テキストスタイル（`app_typography.dart`）  
`AppRadius` — 4px グリッド準拠のボーダー半径トークン（`app_radius.dart`）

---

## ThemeData バインディング

`App` ウィジェットで `AppColorScheme` を Material3 の `ThemeData` と紐づけ、カード・ダイアログ・ボトムシート・AppBar は自動適用されるようにしている。

アプリ側で二度背景色・テキスト色を指定する…という場面がないように必要に応じて `ThemeData` を更新する。

---

## コンポーネント

### AppButton (`app_button.dart`)

一般的なアクションボタン。`variant` で用途を分ける：
- `primary` — 画面の主要アクション（保存・完了など）
- `secondary` — 補助アクション（キャンセルなど）
- `ghost` — 低優先度のテキストアクション
- `danger` — 削除など破壊的アクション

`fullWidth: true` でフォームの送信ボタンなど横幅いっぱいに使う。

---

### AppPillButton (`app_pill_button.dart`)

フルラウンドの小型ボタン。リストアイテムやカード内の「完了」「実行」など、コンテキスト内の主要アクションに使う。`AppButton` より小さく目立たない存在感。

---

### AppIconButton (`app_icon_button.dart`)

主に AppBar 上に表示させ、アイコン操作（編集・フィルタ・ソートなど）に使う。`label` を渡すとアイコン＋テキストの組み合わせになる。

---

### AppBadge (`app_badge.dart`)

ステータスや残り日数など、一言で状態を伝えるラベル。`tone` で色を選ぶ：

- `danger` — 期限超過
- `warning` — 今日・直近
- `success` — 完了・自動周期
- `info` — 一般情報
- `primary` — 強調情報
- `neutral` — 中立的な補足

---

### AppFilterChip (`app_filter_chip.dart`)

一覧画面のフィルタバーに使う切り替えチップ。`isSelected` で選択状態を管理。`count` でアイテム数を添えられる。

---

### AppSearchInput (`app_search_input.dart`)

一覧画面上部の検索フィールド。フォーカス時にプライマリカラーのアウトラインとグローを表示。`showClear` + `onClear` で入力クリアボタンを出す。

---

### AppTaskIconTile (`app_task_icon_tile.dart`)

`TaskItem` のアイコンを表示するコンポーネント。タスクカード・編集画面・ピッカーなどで統一して使う。推奨サイズ: 32 / 40 / 48 / 52dp。

---

### AppProgressBar (`app_progress_bar.dart`)

タスクカード内の進捗表示。`value` に応じて色が変化（info → success → warning）。Material の ProgressBar は使わないこと。
