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

# 削除実行
if [ "$DRY_RUN" = true ]; then
  echo "[dry-run]"
  git branch --merged $DEFAULT_BRANCH | grep -vE "^[* ] ($EXCLUDE_BRANCHES)$" 
else
  git branch --merged $DEFAULT_BRANCH | grep -vE "^[* ] ($EXCLUDE_BRANCHES)$" | xargs -n 1 git branch -d 2>/dev/null || true
fi