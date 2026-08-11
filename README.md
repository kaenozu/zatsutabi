# 雑旅（仮称）

全国どこでも、現在地から日帰り先を1件だけ提案して意思決定を終わらせるFlutter MVPです。

## 方針

- バックエンド、LLM、Google Places、Maps Platform API、ルーティングAPIなし
- 位置情報と端末内推薦で候補を1件に絞る
- Google MapsはAPIではなくMaps URLで外部起動
- POIはOSM由来の正規化SQLiteをアプリに同梱。現状の7件はパイプライン確認用サンプル
- 天気は`WeatherProvider`抽象と`NoWeatherProvider`で分離

## 全国POI生成

Geofabrik Japan PBFを開発環境で取得し、OSMタグから目的地候補だけを正規化したJSONにしてから、`python tool/generate_poi_db.py`でSQLiteを生成します。アプリにPBFは同梱しません。

```text
Japan-latest.osm.pbf → 抽出/正規化 → tool/sample_pois.json相当 → assets/poi_osm.sqlite
```

`flutter pub get`後に`python tool/generate_poi_db.py`を実行すると、件数とDBサイズが表示されます。

## attribution

画面内に `© OpenStreetMap contributors` を表示しています。実データ更新時はOSMのライセンスとデータ利用条件も再確認してください。
