#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="k8s-monitor"

KKS_CONTEXT="${KKS_CONTEXT:-minikube}"
KKS_NAMESPACE="${KKS_NAMESPACE:-default}"

SSK_CONTEXT="${SSK_CONTEXT:-minikube}"
SSK_NAMESPACE="${SSK_NAMESPACE:-default}"

WATCH_INTERVAL="${WATCH_INTERVAL:-5}"
EVENT_LINES="${EVENT_LINES:-15}"
ALERT_COOLDOWN_SECONDS="${ALERT_COOLDOWN_SECONDS:-30}"

STERN_MAX_LOG_REQUESTS="${STERN_MAX_LOG_REQUESTS:-}"
# sternのexclude（正規表現）
STERN_EXCLUDE_REGEX="${STERN_EXCLUDE_REGEX:-""}"
# sternのinclude / Alertの検知条件 （正規表現）
STERN_INCLUDE_REGEX="${STERN_INCLUDE_REGEX:-ERROR}"
LOG_FILTER_REGEX="${LOG_FILTER_REGEX:-${STERN_INCLUDE_REGEX}}"

SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"

# ==============================================================================
# require_*: 起動前チェック
# ==============================================================================

# 指定したコマンドが存在するか確認する。
require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "required command not found: $1" >&2
    exit 1
  }
}

# 指定した Kubernetes context が kubeconfig に存在するか確認する。
require_kube_context() {
  local context="$1"

  kubectl config get-contexts "$context" -o name 2>/dev/null |
    grep -Fxq "$context" || {
      echo "kubectl context not found: $context" >&2
      exit 1
    }
}

# grep -E で使う正規表現が妥当か確認する。
require_valid_grep_regex() {
  local regex="$1"
  local label="$2"
  local status=0

  printf '' | grep -Eq "$regex" >/dev/null 2>&1 || status=$?

  case "$status" in
    0|1)
      ;;
    *)
      echo "invalid grep regex in ${label}: ${regex}" >&2
      exit 1
      ;;
  esac
}

# 起動に必要な外部コマンドと Kubernetes context をまとめて確認する。
require_all() {
  local command_name

  for command_name in tmux kubectl stern watch; do
    require_command "$command_name"
  done

  require_kube_context "$KKS_CONTEXT"
  require_kube_context "$SSK_CONTEXT"
  require_valid_grep_regex "$LOG_FILTER_REGEX" "LOG_FILTER_REGEX"
}

# ==============================================================================
# pane_*: tmux pane 操作
# ==============================================================================

# pane にタイトルを設定し、指定したコマンドを投入して実行する。
pane_setup() {
  local pane_id="$1"
  local title="$2"
  local command="$3"
  local remain_on_exit="${4:-off}"

  tmux select-pane -t "$pane_id" -T "$title"
  tmux set-option -p -t "$pane_id" remain-on-exit "$remain_on_exit"
  tmux respawn-pane -k -t "$pane_id" "$command"
}

# ==============================================================================
# cmd_*: pane に投入するコマンド文字列の生成
# ==============================================================================

# pods 監視用の watch コマンド文字列を生成する。
cmd_pod_watch() {
  local context="$1"
  local namespace="$2"

  printf \
    'watch --interval %q --no-title --exec kubectl --context %q get pods --namespace %q' \
    "$WATCH_INTERVAL" \
    "$context" \
    "$namespace"
}

# events 監視用の watch コマンド文字列を生成する。
cmd_event_watch() {
  local context="$1"
  local namespace="$2"
  local event_command

  printf -v event_command \
    'kubectl --context %q get events --namespace %q --sort-by=.lastTimestamp 2>/dev/null | tail -n %q' \
    "$context" \
    "$namespace" \
    "$EVENT_LINES"

  printf \
    'watch --interval %q --no-title %q' \
    "$WATCH_INTERVAL" \
    "$event_command"
}

# stern pane から、このスクリプト自身を __stern モードで再実行するコマンド文字列を生成する。
cmd_stern() {
  local system_name="$1"
  local context="$2"
  local namespace="$3"

  printf 'bash %q __stern %q %q %q' \
    "$SCRIPT_PATH" \
    "$system_name" \
    "$context" \
    "$namespace"
}

# 手動操作 pane 用のシェル起動コマンドを生成する。
cmd_free_shell() {
  printf 'exec ${SHELL:-bash} -l'
}

# ==============================================================================
# stern_*: stern 実行中の監視・通知処理
# ==============================================================================

# 環境変数から stern の追加引数を組み立てる。
stern_build_args() {
  local -a args

  args=(
    --context "$1"
    --namespace "$2"
    --since 2m
    --tail 5
    --include "$STERN_INCLUDE_REGEX"
    --color always
    --diff-container
  )

  if [[ -n "$STERN_EXCLUDE_REGEX" ]]; then
    args+=(--exclude "$STERN_EXCLUDE_REGEX")
  fi

  if [[ -n "$STERN_MAX_LOG_REQUESTS" ]]; then
    args+=(--max-log-requests "$STERN_MAX_LOG_REQUESTS")
  fi

  printf '%s\0' "${args[@]}"
}

# stern が ERROR 系ログを検知したことを tmux option に一時的に保存する。
stern_show_alert_status() {
  local system_name="$1"
  local alert_time="$2"
  local alert_value="${system_name} ${alert_time}"
  local window_id

  window_id="$(tmux display-message -p -t "$TMUX_PANE" '#{window_id}')"

  tmux set-option -t "$SESSION_NAME" @k8s_alert "$alert_value"
  tmux set-option -t "$SESSION_NAME" @k8s_alert_window "$window_id"
  tmux set-window-option -t "$window_id" @k8s_window_alert "$alert_value"

  (
    local current_value
    local current_window_value

    sleep "$ALERT_COOLDOWN_SECONDS"

    current_value="$(tmux show-options -v -t "$SESSION_NAME" @k8s_alert 2>/dev/null || true)"
    current_window_value="$(tmux show-window-options -v -t "$window_id" @k8s_window_alert 2>/dev/null || true)"

    if [[ "$current_window_value" == "$alert_value" ]]; then
      tmux set-window-option -u -t "$window_id" @k8s_window_alert
    fi

    if [[ "$current_value" == "$alert_value" ]]; then
      tmux set-option -u -t "$SESSION_NAME" @k8s_alert
      tmux set-option -u -t "$SESSION_NAME" @k8s_alert_window
    fi
  ) >/dev/null 2>&1 &
}

# ERROR 系ログ検知時に BEL と macOS 通知を送る。
stern_notify_alert() {
  local system_name="$1"
  local context="$2"
  local namespace="$3"
  local alert_timestamp="$4"

  printf '\a'

  if [[ "$(uname -s)" == "Darwin" ]] &&
    command -v osascript >/dev/null 2>&1; then
    osascript -e \
      "display notification \"ERRORログを検出しました (${alert_timestamp})\" with title \"Kubernetes stern alert [${system_name}]\" subtitle \"${context} / ${namespace}\"" \
      >/dev/null 2>&1 &
  fi
}

# stern の出力を1行ずつ読み、ERROR 系ログだけ通知対象にする。
stern_process_lines() {
  local system_name="$1"
  local context="$2"
  local namespace="$3"
  local last_alert_at=0
  local line
  local now
  local alert_time
  local alert_timestamp

  while IFS= read -r line; do
    printf '%s\n' "$line"

    printf '%s\n' "$line" | grep -Eq "$LOG_FILTER_REGEX" || continue

    now="$(date +%s)"
    (( now - last_alert_at < ALERT_COOLDOWN_SECONDS )) && continue

    alert_time="$(date '+%H:%M:%S')"
    alert_timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    stern_notify_alert "$system_name" "$context" "$namespace" "$alert_timestamp"
    stern_show_alert_status "$system_name" "$alert_time"

    last_alert_at="$now"
  done
}

# 指定された context/namespace に対して stern を起動し、ERROR 系ログを監視する。
stern_run() {
  local system_name="$1"
  local context="$2"
  local namespace="$3"
  local -a stern_args

  clear

  mapfile -d '' -t stern_args < <(stern_build_args "$context" "$namespace")

  stern \
    "${stern_args[@]}" \
    . 2>&1 | stern_process_lines "$system_name" "$context" "$namespace"
}

# ==============================================================================
# window_*: tmux window 作成
# ==============================================================================

# stern ウィンドウを作成する。
# 左 pane に KKS、右 pane に SSK の stern 監視を配置する。
window_create_stern() {
  local left_pane
  local right_pane

  left_pane="$(
    tmux new-session -d -P -F '#{pane_id}' \
      -s "$SESSION_NAME" \
      -n stern
  )"

  right_pane="$(
    tmux split-window -h -P -F '#{pane_id}' \
      -t "$left_pane"
  )"

  pane_setup \
    "$left_pane" \
    "KKS: ${KKS_NAMESPACE} · stern" \
    "$(cmd_stern KKS "$KKS_CONTEXT" "$KKS_NAMESPACE")" \
    on

  pane_setup \
    "$right_pane" \
    "SSK: ${SSK_NAMESPACE} · stern" \
    "$(cmd_stern SSK "$SSK_CONTEXT" "$SSK_NAMESPACE")" \
    on

  tmux select-layout -t "${SESSION_NAME}:stern" even-horizontal
}

# watch ウィンドウを作成する。
# 左列に KKS、右列に SSK を置き、それぞれ上段 pods / 下段 events に分割する。
window_create_watch() {
  local kks_pod_pane
  local ssk_pod_pane
  local kks_event_pane
  local ssk_event_pane

  kks_pod_pane="$(
    tmux new-window -P -F '#{pane_id}' \
      -t "$SESSION_NAME" \
      -n watch
  )"

  ssk_pod_pane="$(
    tmux split-window -h -P -F '#{pane_id}' \
      -t "$kks_pod_pane"
  )"

  kks_event_pane="$(
    tmux split-window -v -p 30 -P -F '#{pane_id}' \
      -t "$kks_pod_pane"
  )"

  ssk_event_pane="$(
    tmux split-window -v -p 30 -P -F '#{pane_id}' \
      -t "$ssk_pod_pane"
  )"

  pane_setup \
    "$kks_pod_pane" \
    "KKS: ${KKS_NAMESPACE} · pods" \
    "$(cmd_pod_watch "$KKS_CONTEXT" "$KKS_NAMESPACE")" \
    on

  pane_setup \
    "$kks_event_pane" \
    "KKS: ${KKS_NAMESPACE} · events" \
    "$(cmd_event_watch "$KKS_CONTEXT" "$KKS_NAMESPACE")" \
    on

  pane_setup \
    "$ssk_pod_pane" \
    "SSK: ${SSK_NAMESPACE} · pods" \
    "$(cmd_pod_watch "$SSK_CONTEXT" "$SSK_NAMESPACE")" \
    on

  pane_setup \
    "$ssk_event_pane" \
    "SSK: ${SSK_NAMESPACE} · events" \
    "$(cmd_event_watch "$SSK_CONTEXT" "$SSK_NAMESPACE")" \
    on
}

# free ウィンドウを作成する。
# 左 pane に KKS、右 pane に SSK の手動操作用シェルを配置する。
window_create_free() {
  local left_pane
  local right_pane

  left_pane="$(
    tmux new-window -P -F '#{pane_id}' \
      -t "$SESSION_NAME" \
      -n free
  )"

  right_pane="$(
    tmux split-window -h -P -F '#{pane_id}' \
      -t "$left_pane"
  )"

  pane_setup \
    "$left_pane" \
    "KKS: ${KKS_NAMESPACE} · free" \
    "$(cmd_free_shell)" \
    off

  pane_setup \
    "$right_pane" \
    "SSK: ${SSK_NAMESPACE} · free" \
    "$(cmd_free_shell)" \
    off

  tmux select-layout -t "${SESSION_NAME}:free" even-horizontal
}

# ==============================================================================
# session_*: tmux session 操作
# ==============================================================================

# 既存の監視用 tmux セッションを終了する。
session_stop() {
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
    echo "stopped: $SESSION_NAME"
  else
    echo "not running: $SESSION_NAME"
  fi
}

# 監視用 tmux セッション全体を作成する。
# stern / watch / free の3ウィンドウを作り、最後に stern を選択する。
session_create_monitor() {
  window_create_stern
  window_create_watch
  window_create_free

  tmux select-window -t "${SESSION_NAME}:stern"
}

# ==============================================================================
# main
# ==============================================================================

# エントリポイント。
# 通常起動、終了、stern 内部起動モードを振り分ける。
main() {
  case "${1:-}" in
    __stern)
      stern_run \
        "${2:?system name required}" \
        "${3:?context required}" \
        "${4:?namespace required}"
      ;;
    --kill)
      require_command tmux
      session_stop
      ;;
    "")
      require_all

      if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux attach-session -t "$SESSION_NAME"
        exit 0
      fi

      session_create_monitor
      tmux attach-session -t "$SESSION_NAME"
      ;;
    *)
      echo "Usage: tmp/scripts/k8s-monitor.sh [--kill]" >&2
      exit 2
      ;;
  esac
}

main "$@"
