# raspi（Raspberry Pi 5）での作業

このマシンは Raspberry Pi 5 の開発用サーバー。持ち主はスマホや Mac から SSH で指示を出していることが多い。

## 環境

- Ubuntu 26.04 LTS / arm64 / 4 コア / メモリ 8GB（+ zram スワップ 4GB）。x86 向けのバイナリや Docker イメージは動かないことがある
- Node.js 22（`npm install -g` は `~/.npm-global` に入る。sudo 不要）、Rust（cargo）、Python 3
- ローカル LLM: Ollama（`http://localhost:11434`、`qwen2.5-coder:1.5b` / `deepseek-r1:1.5b`）。約 7 tokens/s なので軽い処理向け
- 作業場所は `~/src`。GitHub へは SSH（アカウント `k1kk1`）で接続できる

## 進め方

- 応答は日本語で、短く。スマホで読むことが多いので、長い出力やコード全文の貼り付けは避け、要点と変更したファイルを示す
- 重い処理（大きなビルド、並列テスト、大きなモデル）はメモリ不足になりやすい。まず対象を絞って実行する（例: `cargo build -j 2`、テストはファイルを指定）
- `sudo` は使わない（設定で禁止している）。パッケージの追加やシステム設定の変更が必要なときは、コマンドを示して持ち主に頼む
- `git push` や PR の作成は確認を取ってから
- Codex を使うときは `codex exec --sandbox workspace-write` で
- 常駐サービス（ollama、grafana-server、prometheus など）や Tailscale を止めたり再起動したりしない
