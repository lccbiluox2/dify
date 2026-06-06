#!/usr/bin/env bash
# Dify 内网断网部署：一键关闭/设置所有官方外网依赖
#
# 用法（在能执行 kubectl 的机器上，如 master1）：
#   chmod +x dify-offline-hardening.sh
#   ./dify-offline-hardening.sh
#
# 自定义命名空间 / PyPI 镜像地址：
#   NAMESPACE=dify PIP_MIRROR_URL=http://pypiserver:8080/simple/ ./dify-offline-hardening.sh
#
# 不等待 Pod 滚动（环境变量已写入，更新在后台进行，推荐卡住时使用）：
#   WAIT_ROLLOUT=0 ./dify-offline-hardening.sh
#
# 仅预览不执行：
#   DRY_RUN=1 ./dify-offline-hardening.sh

set -euo pipefail

# ---------- 可覆盖参数 ----------
NAMESPACE="${NAMESPACE:-dify}"
PIP_MIRROR_URL="${PIP_MIRROR_URL:-http://pypiserver:8080/simple/}"
DRY_RUN="${DRY_RUN:-0}"
# 1=等待滚动完成；0=只写环境变量立即退出（推荐内网环境，避免“卡死”感）
WAIT_ROLLOUT="${WAIT_ROLLOUT:-0}"
# 单个 Deployment 滚动超时（秒）
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-120}"
# 逗号分隔，仅等待这些 Deployment；留空则等待本次实际更新过的全部
# 示例：ROLLOUT_WAIT_ONLY=dify-plugin-daemon
ROLLOUT_WAIT_ONLY="${ROLLOUT_WAIT_ONLY:-dify-plugin-daemon}"

# API / Worker 共用：关闭 Dify 官方外网服务
API_ENVS=(
  "MARKETPLACE_ENABLED=false"
  "CHECK_UPDATE_URL="
  "CREATORS_PLATFORM_FEATURES_ENABLED=false"
  "ENABLE_CHECK_UPGRADABLE_PLUGIN_TASK=false"
  "HOSTED_FETCH_APP_TEMPLATES_MODE=builtin"
  "HOSTED_FETCH_PIPELINE_TEMPLATES_MODE=builtin"
  "ENABLE_WEBSITE_JINAREADER=false"
  "ENABLE_WEBSITE_FIRECRAWL=false"
  "ENABLE_WEBSITE_WATERCRAWL=false"
  "SCARF_NO_ANALYTICS=true"
)

WEB_ENVS=(
  "MARKETPLACE_ENABLED=false"
  "NEXT_TELEMETRY_DISABLED=1"
  "EDITION=SELF_HOSTED"
  "ENABLE_WEBSITE_JINAREADER=false"
  "ENABLE_WEBSITE_FIRECRAWL=false"
  "ENABLE_WEBSITE_WATERCRAWL=false"
  "CREATORS_PLATFORM_FEATURES_ENABLED=false"
)

PLUGIN_ENVS=(
  "PIP_MIRROR_URL=${PIP_MIRROR_URL}"
  "PLUGIN_IGNORE_UV_LOCK=true"
)

SANDBOX_ENVS=(
  "ENABLE_NETWORK=false"
)

API_DEPLOYS=(dify-api dify-worker dify-worker-beat dify-celery-worker dify-celery-beat)
WEB_DEPLOYS=(dify-web dify-webapp)
PLUGIN_DEPLOYS=(dify-plugin-daemon dify-plugin_daemon plugin-daemon)
SANDBOX_DEPLOYS=(dify-sandbox sandbox)
WEAVIATE_DEPLOYS=(weaviate dify-weaviate)

# 记录本次成功 patch 的 Deployment
UPDATED_DEPLOYS=()

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[DRY-RUN] $*"
  else
    log "$*"
    eval "$@"
  fi
}

deployment_exists() {
  kubectl get deployment "$1" -n "$NAMESPACE" &>/dev/null
}

track_updated() {
  local dep="$1"
  local existing
  for existing in "${UPDATED_DEPLOYS[@]:-}"; do
    [[ "$existing" == "$dep" ]] && return 0
  done
  UPDATED_DEPLOYS+=("$dep")
}

set_deploy_env() {
  local deploy="$1"
  shift
  local -a envs=("$@")
  if ! deployment_exists "$deploy"; then
    return 1
  fi
  # shellcheck disable=SC2068
  run kubectl set env "deployment/${deploy}" -n "$NAMESPACE" ${envs[@]}
  track_updated "$deploy"
  return 0
}

apply_to_list() {
  local -n dep_list=$1
  local -n env_list=$2
  local label="$3"
  local found=0

  for dep in "${dep_list[@]}"; do
    if set_deploy_env "$dep" "${env_list[@]}"; then
      log "✓ ${label}: ${dep} 环境变量已写入"
      found=1
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    log "⚠ 未找到 ${label} Deployment（已跳过）"
  fi
}

should_wait_deploy() {
  local dep="$1"
  if [[ -z "$ROLLOUT_WAIT_ONLY" ]]; then
    return 0
  fi
  local item
  IFS=',' read -ra items <<< "$ROLLOUT_WAIT_ONLY"
  for item in "${items[@]}"; do
    item="${item// /}"
    [[ "$item" == "$dep" ]] && return 0
  done
  return 1
}

wait_rollouts() {
  if [[ "$WAIT_ROLLOUT" != "1" ]] || [[ "$DRY_RUN" == "1" ]]; then
    log "跳过滚动等待（WAIT_ROLLOUT=${WAIT_ROLLOUT}）。Pod 会在后台陆续重启。"
    log "手动查看：kubectl get pods -n ${NAMESPACE} -w"
    return 0
  fi

  local dep
  for dep in "${UPDATED_DEPLOYS[@]:-}"; do
    if ! should_wait_deploy "$dep"; then
      log "跳过等待: ${dep}（不在 ROLLOUT_WAIT_ONLY 列表）"
      continue
    fi
    log "等待滚动更新: ${dep}（超时 ${ROLLOUT_TIMEOUT}s，可 Ctrl+C 中断，环境变量已生效）"
    if kubectl rollout status "deployment/${dep}" -n "$NAMESPACE" --timeout="${ROLLOUT_TIMEOUT}s"; then
      log "✓ ${dep} 滚动完成"
    else
      log "⚠ ${dep} 滚动超时或失败，请另开终端排查："
      log "    kubectl get pods -n ${NAMESPACE} | grep ${dep}"
      log "    kubectl describe pod -n ${NAMESPACE} -l app.kubernetes.io/name=${dep}"
      log "    kubectl get events -n ${NAMESPACE} --sort-by=.lastTimestamp | tail -20"
    fi
  done
}

verify_env() {
  local deploy="$1"
  shift
  local -a keys=("$@")
  if ! deployment_exists "$deploy"; then
    return 0
  fi
  log "--- 验证 Deployment 模板中的 ${deploy} ---"
  for key in "${keys[@]}"; do
    local val
    val=$(kubectl get deployment "$deploy" -n "$NAMESPACE" \
      -o "jsonpath={.spec.template.spec.containers[0].env[?(@.name=='${key}')].value}" 2>/dev/null || true)
    printf '  %s=[%s]\n' "$key" "$val"
  done
}

main() {
  log "Dify 内网断网加固 | namespace=${NAMESPACE} | PIP_MIRROR_URL=${PIP_MIRROR_URL}"
  log "WAIT_ROLLOUT=${WAIT_ROLLOUT} | ROLLOUT_WAIT_ONLY=${ROLLOUT_WAIT_ONLY:-全部} | ROLLOUT_TIMEOUT=${ROLLOUT_TIMEOUT}s"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY_RUN=1，仅打印命令"
  fi

  if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    log "错误: 命名空间 ${NAMESPACE} 不存在"
    exit 1
  fi

  # 阶段 1：批量写入环境变量（触发滚动更新）
  apply_to_list API_DEPLOYS API_ENVS "API/Worker"
  apply_to_list WEB_DEPLOYS WEB_ENVS "Web"
  apply_to_list PLUGIN_DEPLOYS PLUGIN_ENVS "Plugin Daemon"
  apply_to_list SANDBOX_DEPLOYS SANDBOX_ENVS "Sandbox"

  for dep in "${WEAVIATE_DEPLOYS[@]}"; do
    if set_deploy_env "$dep" "DISABLE_TELEMETRY=true"; then
      log "✓ Weaviate: ${dep} 环境变量已写入"
    fi
  done

  # 阶段 2：可选等待（默认不等待，避免长时间阻塞）
  wait_rollouts

  # 阶段 3：验证（读 Deployment 模板，不依赖 Pod 是否已重启完成）
  log "========== 验证关键环境变量（Deployment 模板）=========="
  verify_env dify-api MARKETPLACE_ENABLED CHECK_UPDATE_URL ENABLE_CHECK_UPGRADABLE_PLUGIN_TASK
  verify_env dify-worker MARKETPLACE_ENABLED CHECK_UPDATE_URL
  verify_env dify-plugin-daemon PIP_MIRROR_URL PLUGIN_IGNORE_UV_LOCK
  verify_env dify-web MARKETPLACE_ENABLED NEXT_TELEMETRY_DISABLED EDITION

  log "完成。"
  log "  · 环境变量已写入 Deployment；各服务会滚动重启生效"
  log "  · 若 Pod 长时间 Terminating：kubectl delete pod <name> -n ${NAMESPACE} --grace-period=0 --force"
  log "  · 确认插件镜像：kubectl exec -n ${NAMESPACE} deploy/dify-plugin-daemon -- sh -c 'echo \$PIP_MIRROR_URL \$PLUGIN_IGNORE_UV_LOCK'"
}

main "$@"
