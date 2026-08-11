# 雑旅（仮称）

全国どこでも、現在地から日帰り先を1件だけ提案して意思決定を終わらせるFlutter MVPです。

## 方針

- バックエンド、LLM、Google Places、Maps Platform API、ルーティングAPIなし
- 位置情報と端末内推薦で候補を1件に絞る
- Google MapsはAPIではなくMaps URLで外部起動
- POIはOSM由来の正規化SQLiteをアプリに同梱。現在の同梱DBは全国21,862件（生成時点）
- 天気は`WeatherProvider`抽象と`NoWeatherProvider`で分離

## 全国POI生成

Geofabrik Japan PBFを開発環境で取得し、`osmium`でOSMタグから目的地候補だけを抽出してSQLiteを生成します。アプリにPBFは同梱しません。

```text
Japan-latest.osm.pbf → tool/extract_osm_pois.py → assets/poi_osm.sqlite
```

実データ生成は次の手順です。

```powershell
python -m pip install osmium
curl.exe -L -o tool/japan-latest.osm.pbf https://download.geofabrik.de/asia/japan-latest.osm.pbf
python tool/extract_osm_pois.py tool/japan-latest.osm.pbf assets/poi_osm.sqlite
```

コマンドは入力PBFサイズ、抽出件数、生成SQLiteサイズを表示します。`tool/generate_poi_db.py`は小さなサンプル入力でパイプラインを確認する用途です。

既定では高速な名称付きPOIノードを抽出します。公園や施設ポリゴンなどのWayも含める場合は`--include-ways`を付けますが、全国PBFでは処理時間とメモリが増えるため、MVPの初期生成ではノード抽出を推奨します。

## attribution

画面内に `© OpenStreetMap contributors` を表示しています。実データ更新時はOSMのライセンスとデータ利用条件も再確認してください。
