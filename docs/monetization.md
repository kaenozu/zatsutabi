# マネタイズ設定と検証証跡

## 決定

無料コア体験（距離を選んで日帰り先を1件決めること）は常に利用可能なまま、ホーム下部に非強制のAdMobバナーを表示する。広告の読み込み中・失敗時はバナーを表示せず、推薦や履歴には影響しない。

## 設定の分離

- Dartの既定値はGoogle公式のテストApp ID / バナーIDだけを使用する。
- 本番値はリポジトリへ保存せず、`--dart-define=ZATSUTABI_PRODUCTION_ADS=true` と各`ADMOB_*`の`--dart-define`で注入する。
- AndroidのApp IDは`-PadmobAppId=...`でGradleへ注入できる。未指定時はテストApp ID。
- iOSターゲットは現行リポジトリに未生成のため、`ios/Runner/Info.plist`の
  `GADApplicationIdentifier`へiOS App IDを設定する工程は未実施。iOSターゲット追加時にテスト値を先に設定し、本番値は署名ビルド環境の設定で置換する。

## 本番引き継ぎ（未確認）

1. AdMobでAndroid/iOSアプリとバナー広告ユニットを作成する。
2. AdMobのテスト値を本番値へ置き換え、Play Console / App Store Connectの広告・プライバシー申告を完了する。
3. 署名済みビルドで、広告表示・失敗時のコア体験継続・同意フローを実機確認する。
4. App ID、広告ユニット、ストア申告、実機runtimeの各結果を別々のリリース証跡に記録する。

このPRでは実AdMobアカウント、実広告ID、ストア設定、課金設定、実機runtimeは確認していない。これらは外部リリースゲートとして残る。
