# Kubernetes Monitor

`k8s-monitor.sh` は、2つの Kubernetes クラスタ (KKS / SSK) を効率よく監視するための tmux セッションを構築するスクリプトです。

tmux・Ghostty・macOS通知を組み合わせることで、

- ログ監視
- Pod状態監視
- Event監視
- 手動操作

を一つのワークスペースで行えるようにしています。

---

# 全体構成

```
Ghostty
    │
    ▼
tmux session (k8s-monitor)
├── stern
│   ├── KKS
│   └── SSK
│
├── watch
│   ├── KKS Pods
│   ├── KKS Events
│   ├── SSK Pods
│   └── SSK Events
│
└── free
    ├── KKS Shell
    └── SSK Shell
```

---

# 目的

複数クラスタを監視する場合、

- Pod一覧
- Event
- Log
- kubectl操作

を頻繁に切り替える必要があります。

このスクリプトでは、それらを最初からレイアウト済みの tmux セッションとして起動し、

- 操作ミスを減らす
- ウィンドウ切り替えを減らす
- ログ異常を即座に通知する

ことを目的としています。

---

# ウィンドウ構成

## stern

リアルタイムログ監視です。

```
+----------------------+----------------------+
| KKS stern            | SSK stern            |
+----------------------+----------------------+
```

各 pane では

```
stern
```

が実行されます。

監視対象は

- ERROR
- Exception
- Panic

のみです。

正常ログは表示しません。

---

## watch

クラスタ状態監視です。

```
+----------------------+----------------------+
| KKS Pods             | SSK Pods             |
|                      |                      |
+----------------------+----------------------+
| KKS Events           | SSK Events           |
+----------------------+----------------------+
```

上段

```
kubectl get pods
```

下段

```
kubectl get events
```

を watch で定期更新します。

---

## free

手動操作用です。

```
+----------------------+----------------------+
| KKS Shell            | SSK Shell            |
+----------------------+----------------------+
```

それぞれ

```
alias k="kubectl --context ... --namespace ..."
```

が設定されています。

そのため

```
k get pod
k logs
k describe pod
```

などをそのまま実行できます。

---

# Ctrl-C の扱い

監視用 pane は誤操作防止のため Ctrl-C を無効化しています。

対象

- stern
- watch

これらは長時間動かし続けることを前提としています。

停止したい場合は

```
Prefix + X
```

で pane を閉じます。

free pane は通常通り Ctrl-C が利用できます。

---

# アラート

stern が

- error
- exception
- panic

を検知すると

1. BEL を送信
2. macOS通知
3. tmux statusへ表示

を行います。

一定時間は同じ通知を繰り返さないように
クールダウンが設定されています。

---

# tmux ステータス表示

通常

```
2026-06-28 18:00:00
```

のみ表示されます。

異常検知時は

```
⚠ KKS 18:01:35
```

のように表示されます。

一定時間経過すると自動で消えます。

---

# Ghostty との連携

Ghostty は BEL を受信すると

- システム警告音
- Dock バッジ
- タイトル強調

を行います。

そのため、

他のウィンドウで作業中でも異常を認識できます。

tmux 側では BEL のみ送信しており、
通知表示は Ghostty に任せています。

---

# pane タイトル

各 pane は

```
KKS: default · stern

SSK: default · pods

KKS: default · events

SSK: default · free
```

のようなタイトルになります。

tmux.conf の

```
pane-border-status top
```

により、常に表示されます。

---

# セッションタイトル

Ghostty のタイトルバーには

```
k8s-monitor · 1:stern · ~/project
```

のように

```
Session · Window · Directory
```

が表示されます。

複数タブでも現在位置を把握しやすくしています。

---

# 操作

起動

```bash
./k8s-monitor.sh
```

既存セッションがある場合は自動で attach します。

停止

```bash
./k8s-monitor.sh --kill
```

---

# 必要コマンド

- tmux
- kubectl
- stern
- watch

---

# 環境変数

|変数|内容|既定値|
|----|----|-------|
|KKS_CONTEXT|KKS Context|minikube|
|KKS_NAMESPACE|KKS Namespace|default|
|SSK_CONTEXT|SSK Context|minikube|
|SSK_NAMESPACE|SSK Namespace|default|
|WATCH_INTERVAL|watch更新間隔|5|
|EVENT_LINES|表示するEvent数|15|
|ALERT_COOLDOWN_SECONDS|通知抑止時間|30|
|STERN_MAX_LOG_REQUESTS|stern の `--max-log-requests`|未指定|
|STERN_EXCLUDE_REGEX|stern の `--exclude` 正規表現|空|
|STERN_INCLUDE_REGEX|stern の `--include` 正規表現|`(?i)(error|exception|panic)`|
|LOG_FILTER_REGEX|通知判定用の正規表現|`STERN_INCLUDE_REGEX` と同じ|

---

# 設計方針

- ログは stern
- 状態監視は watch
- 操作は free

という役割を明確に分離しています。

監視用 pane は停止しにくくし、
操作は free pane のみで行うことで、
監視が意図せず止まる事故を防止しています。

tmux はレイアウト管理、
Ghostty は通知管理を担当し、
それぞれの責務を分離しています。
