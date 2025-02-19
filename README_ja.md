# Azure Container Apps で OpenTelemetry データを収集して Application Insights に転送する

Azure Container Apps 環境で OpenTelemetry データ エージェントを使用しつつ、Go Webサーバーからテレメトリ情報を送信するサンプルです。

Applicaiton Insights 現時点（2025/02）で、ログとトレースのみのサポートです。

- :o: ログ
- :o: トレース
- :x: メトリック

## Azure の構成

作成するリソースは以下の通り。

- ユーザー割り当てマネージドID
- Azure コンテナレジストリ
- **Application Insights**
- Azure Container App Env **with OpenTelemetry**
- Azure Container Apps

ユーザー割り当てマネージドID は、Azure Container Apps から Azure Container Registry にアクセスするために必要ですで、ACR Pull の ロールを割り当てます。

Azure Container App Env OpenTelemetry の拡張機能を有効にします。接続先は、 Application Insights にします。

## ソース構成

OpenTelemetry の初期化については、以下のドキュメントを参考にしています。

[Getting Started | OpenTelemetry](https://opentelemetry.io/docs/languages/go/getting-started/)

OpenTelemetry を構成すると、以下の環境変数が自動で構成されます。GoのOpenTelemetry SDK は、これらの環境変数が設定されていると、自動で構成してくれます。

- OTEL_EXPORTER_OTLP_ENDPOINT
- OTEL_EXPORTER_OTLP_PROTOCOL
- OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
- OTEL_EXPORTER_OTLP_METRICS_ENDPOINT
- OTEL_EXPORTER_OTLP_LOGS_ENDPOINT

構成されていない場合、 stderr にログが出力されるよう改造しています。これはローカルで確認するためです。

Webサーバーもサンプルを利用しています。 `rolldice/{player}` にアクセスすると、サイコロを振って結果を返します。



## デプロイ手順

はじめに `Makefile` の `SUFFIX` を適当に修正して、リソース名がグローバルに重複しないようにします。
その後は以下の手順で進めてください。

```sh
make rg    # ソースグループを作成
make env   # Container Apps 環境とACRの作成

export ACR_NAME=<acr-name>  # ACRの名前を設定

make acr-login              # acr にログイン
make build-image            # イメージをビルド＆プッシュ
make deploy                 # Container Apps にデプロイ
```

## Application Insights

以下のような内容が確認できます

<img src=".media/example-1.png" width="600">

## リンク

[Azure Container Apps で OpenTelemetry データを収集して読み取る (プレビュー) | Microsoft Learn](https://learn.microsoft.com/ja-jp/azure/container-apps/opentelemetry-agents?tabs=arm%2Carm-example)