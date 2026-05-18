# TrainMemo

TrainMemo は、複数の YouTube 動画を日替わりで回しながら筋トレ習慣を記録する SwiftUI アプリです。

## 機能

- 登録した動画数に合わせて今日の筋トレ動画をローテーション表示
- 「今日」タブから登録済みの YouTube URL を起動
- SwiftData で日々の完了記録を保存、取り消し
- 連続日数、合計日数、月ごとの完了カレンダー、日別詳細を表示
- 動画タイトル、URL、時間、並び順、動画数を編集
- ローテーション開始日を設定
- 今後の筋トレ日にローカル通知を予約

## 要件

- Xcode 16 以降
- iOS 17.0 以降
- Swift 6

## 構成

```text
TrainMemo/
  App/        アプリのエントリポイントと SwiftData コンテナ設定
  Models/     SwiftData モデル
  Services/   初期データ投入、動画ローテーション、通知スケジューリング
  Views/      今日、記録、設定、タブ表示
TrainMemoTests/
  WorkoutSchedulerTests.swift
```

## ビルド

Xcode で `TrainMemo.xcodeproj` を開き、`TrainMemo` スキームを実行します。

コマンドラインからビルドする場合:

```sh
xcodebuild -project TrainMemo.xcodeproj \
  -scheme TrainMemo \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## テスト

ユニットテストでは、動画ローテーション、連続日数の計算、同日ログの重複排除、月カレンダーの生成を確認しています。

```sh
xcodebuild -project TrainMemo.xcodeproj \
  -scheme TrainMemo \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

## メモ

初回起動時に5本のプレースホルダー動画が作成されます。実際に使う前に「設定」タブから動画情報を編集してください。
