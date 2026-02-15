#!/bin/bash

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
fi

DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed "s@^refs/remotes/origin/@@")
if [ -z "$DEFAULT_BRANCH" ]; then
    if git show-ref --verify --quiet refs/heads/main; then
        DEFAULT_BRANCH="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        DEFAULT_BRANCH="master"
    else
        echo "デフォルトブランチが特定できません"
        exit 1
    fi
fi

# 除外パターン（設定可能）
EXCLUDE_BRANCHES=$(git config --get branch.clean.exclude || echo "main|master|develop|development|staging|production|prod|release")

# worktreeで使用中のブランチを取得
WORKTREE_BRANCHES=""
if git worktree list --porcelain >/dev/null 2>&1; then
    WORKTREE_BRANCHES=$(git worktree list --porcelain | grep '^branch refs/heads/' | sed 's@^branch refs/heads/@@')
fi

is_worktree_branch() {
    local branch="$1"
    echo "$WORKTREE_BRANCHES" | grep -Fqx "$branch"
}

# マージ済みブランチ一覧を取得（除外パターンでフィルタ）
MERGED_BRANCHES=$(git branch --merged "$DEFAULT_BRANCH" | grep -vE "^[* +] ($EXCLUDE_BRANCHES)$" | sed 's/^[* +] //')

# マージ済みブランチからworktree使用中のブランチを除外して削除
if [ "$DRY_RUN" = true ]; then
    echo "[dry-run]"
fi
while read -r branch; do
    [ -z "$branch" ] && continue
    if [ -n "$WORKTREE_BRANCHES" ] && is_worktree_branch "$branch"; then
        continue
    fi
    if [ "$DRY_RUN" = true ]; then
        echo "  $branch"
    else
        git branch -d "$branch"
    fi
done <<< "$MERGED_BRANCHES"