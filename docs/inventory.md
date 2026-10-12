# playbook / host group の運用設計

## 概要

playbook と inventory の host group をどう使い分け、どのような運用を想定しているかを説明する。

| 仕組み | 表すもの | 例 |
|---|---|---|
| playbook | 環境の種類 | 作業用マシン、サービス用サーバー |
| host group | 同じ playbook の中で、ホストを何に使うか | デスクトップ、アプリケーション開発 |
| tags | role 単位の実行の絞り込み | `--tags golang` |

個々の構成は次のファイルを正とする。

| 情報 | ファイル |
|---|---|
| 各 group の用途 | `inventories/*.example` のコメント |
| group ごとに実行される role | `playbook-*.yml` の各 play の `hosts:` と `roles:` |
| E2E テストでコンテナを所属させる group | `molecule/*/molecule.yml` の `groups` |

## 設計方針

### playbook と group の使い分け

「1 台のホストが両方に属することがあるか」で使い分ける。

- 属することがある場合は、同じ playbook の中の group として表す
  - 例: macOS をデスクトップ兼開発機として使う場合、デスクトップ用の group と開発用の group の両方に属する
- 属さない場合や、同じホストに適用すると衝突する場合は、playbook を分ける
  - 同じ role を違うパラメータで使う (例: nodejs のメジャーバージョンが違う)
  - 前提となる環境が違う (例: Kubernetes のノードは swap 無効、コンテナランタイムが必要)
  - ホストをまたいだ順序が必要 (例: control plane を初期化してから worker を参加させる)

1 台のホストは 1 つの playbook の group に属する。同じ role が複数の playbook に現れることはあるが、適用されるホストが重ならないため、パラメータが違っても衝突しない。

### playbook の構成

- group による制御は play の `hosts:` で行う。どの group にどの role が入るかは、play の `hosts:` を見れば分かる
- 1 つの playbook の中では、各 role を 1 つの play に書く。Ansible が role の重複実行を省くのは同じ play の中だけのため、複数の group に属するホストでも各 role は 1 回だけ実行される ([Running a role multiple times in one play](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#running-a-role-multiple-times-in-one-play))
- 複数の group で使う role は、和集合のパターン (例: `hosts: webapp:terraform`) を対象にした play に置く ([Patterns](https://docs.ansible.com/ansible/latest/inventory_guide/intro_patterns.html))
- 和集合の play が増えすぎる場合は、一部のホストに不要な role が入ることを許容し、より広いパターンの play にまとめる
- role の実行順は play の順で決まる。前提となる role (パッケージマネージャの設定など) は前の play に置く

### OS の違い

OS の違い (Ubuntu / macOS など) は role の中で `ansible_facts.distribution` によって振り分ける。group は用途だけを表す。

## 想定する運用

### inventory の管理

リポジトリを公開しているため、実際のホストを書いた inventory は各実行環境で管理し、git 管理外とする (`.gitignore` の `/inventories/*`)。リポジトリには playbook ごとの雛形 (`inventories/<playbook>.example`) を置き、group の定義と用途を示す。

### セットアップの実行形態

次の 2 つの形態を想定し、どちらも同じ playbook と group の定義を使う。

- 対象ホスト上でリポジトリを clone し、自身をセットアップする
  - inventory では `localhost` (`ansible_connection=local`) を該当する group に所属させる。ホスト名は inventory に現れない
- 別のマシンから SSH でリモートのホストをセットアップする
  - inventory に接続先を書き、`--limit` で group やホストを絞り込む
  - ホスト名を inventory に書きたくない場合は `~/.ssh/config` の別名を使う。公開したくない group 変数は git 管理外の `inventories/group_vars/` に置く ([Organizing host and group variables](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#organizing-host-and-group-variables))

### 構成の変更

- role の追加は、その role を使う group の組み合わせを対象にした play への追記で表す
- 用途の追加は group の追加で表し、雛形・playbook の play・E2E テストの scenario がそろって変わる
- 環境の種類の追加は playbook の追加で表し、playbook ごとに雛形と E2E テストの scenario を持つ

### E2E テスト

molecule の scenario は、コンテナを所属させる group の組み合わせごとに用意する。1 つの playbook に対して、group の組み合わせを変えた複数の scenario を持つ。
