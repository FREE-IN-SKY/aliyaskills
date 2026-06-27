#!/usr/bin/env bash
# 严格白名单：只放行只读 git 查询，其余一律拦截
# 扫描复合命令中所有 git 调用(rtk git 同等对待)，任一非只读即拦
input=$(cat)
cmd=$(echo "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)

# 空命令放行
[ -z "$cmd" ] && exit 0

# 归一化：rtk git 视同 git
norm=$(echo "$cmd" | sed -E 's/\brtk git\b/git/g')

# 无 git 调用 -> 放行(非git命令)
echo "$norm" | grep -qE '\bgit ' || exit 0

blocked=0

# 提取每个 git 子命令词，任一非只读即拦
while IFS= read -r sub; do
  [ -z "$sub" ] && continue
  case "$sub" in
    status|log|diff|branch|show|ls-files|blame|reflog|remote) ;;
    *) blocked=1 ;;
  esac
done < <(echo "$norm" | grep -oE '\bgit [a-zA-Z][a-zA-Z-]*' | sed -E 's/^git //')

# remote 特殊：只允许 git remote -v，其余 git remote 一律拦
if echo "$norm" | grep -qE '\bgit remote\b'; then
  rest=$(echo "$norm" | sed -E 's/\bgit remote -v\b//g')
  if echo "$rest" | grep -qE '\bgit remote\b'; then
    blocked=1
  fi
fi

if [ "$blocked" -eq 0 ]; then
  exit 0
fi

echo "BLOCKED: 仅允许只读 git 查询(status/log/diff/branch/remote -v/show/ls-files/blame/reflog)。其余命令拦截。" >&2
exit 2
