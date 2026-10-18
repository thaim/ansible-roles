## 概要


## E2E
`playbook-*.yml` / `roles/**` / `filter_plugins/**` / `molecule/**` / 依存ファイル (`pyproject.toml` / `poetry.lock` / `requirements.yml`) を変更した PR は、merge 前に E2E を実行する。
PR に `/e2e` とコメントすると PR ブランチで Molecule E2E が実行され、結果が PR にコメントされる。push 後の再実行も同じ `/e2e` で行う。

- [ ] E2E が不要な変更である、または最新の commit で `/e2e` が成功した
