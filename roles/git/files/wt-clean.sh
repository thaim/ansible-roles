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

if [ "$DRY_RUN" = true ]; then
    echo "[dry-run]"
fi

FIRST_ENTRY=true
WT_PATH=""
WT_BRANCH=""

while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == worktree\ * ]]; then
        WT_PATH="${line#worktree }"
        WT_BRANCH=""
    elif [[ "$line" == branch\ refs/heads/* ]]; then
        WT_BRANCH="${line#branch refs/heads/}"
    elif [ -z "$line" ]; then
        if [ "$FIRST_ENTRY" = true ]; then
            FIRST_ENTRY=false
            WT_PATH=""
            WT_BRANCH=""
            continue
        fi

        if [ -z "$WT_BRANCH" ]; then
            WT_PATH=""
            WT_BRANCH=""
            continue
        fi

        if git merge-base --is-ancestor "$WT_BRANCH" "$DEFAULT_BRANCH" 2>/dev/null; then
            if [ "$DRY_RUN" = true ]; then
                echo "  $WT_PATH ($WT_BRANCH)"
            else
                git worktree remove "$WT_PATH"
                git branch -d "$WT_BRANCH"
            fi
        fi

        WT_PATH=""
        WT_BRANCH=""
    fi
done < <(git worktree list --porcelain; echo "")
