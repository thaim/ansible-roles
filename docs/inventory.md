# playbook / host group の運用設計

## 概要

このドキュメントでは、playbook と inventory の host group の使い分けと、それに沿った運用手順を説明する。個々の playbook・group・role の一覧は書かない。それぞれ次のファイルを正とする。

| 知りたいこと | 参照するファイル |
|---|---|
| 各 group の用途 | `inventories/*.example` のコメント |
| group ごとに実行される role | `playbook-*.yml` の各 play の `hosts:` と `roles:` |
| E2E テストで所属させる group | `molecule/*/molecule.yml` の `groups` |

playbook / host group / tags は、それぞれ次のものを表す。

| 仕組み | 表すもの | 例 |
|---|---|---|
| playbook | 環境の種類 | 作業用マシン、サービス用サーバー |
| host group | 同じ playbook の中で、ホストを何に使うか | デスクトップ、アプリケーション開発 |
| tags | role 単位で実行を絞り込む | `--tags golang` |

## 設計方針

### playbook を分けるか、group を追加するかの判断基準

「1 台のホストが両方に属することがあるか」で判断する。

- 属することがある → 同じ playbook の中で group を追加する
  - 例: macOS をデスクトップ兼開発機として使う場合、デスクトップ用の group と開発用の group の両方に属する
- 属さない、または同じホストに適用すると衝突する → playbook を分ける
  - 同じ role を違うパラメータで使う (例: nodejs のメジャーバージョンが違う)
  - 前提となる環境が違う (例: Kubernetes のノードは swap 無効、コンテナランタイムが必要)
  - ホストをまたいだ順序が必要 (例: control plane を初期化してから worker を参加させる)

1 台のホストは、1 つの playbook の group にだけ属させる。同じ role が複数の playbook に出てくるのは構わない。適用されるホストが重ならないので、パラメータが違っても衝突しない。

### playbook の書き方

- group の制御は play の `hosts:` だけで行う。role に `when: "'webapp' in group_names"` のような group 判定は書かない
  - どの group にどの role が入るかを、play の `hosts:` を見るだけで判断できるようにするため
- 各 role は 1 つの play にだけ書く
  - Ansible が role の重複実行を省くのは同じ play の中だけ。別の play に同じ role を書くと、両方の group に属するホストでは 2 回実行される ([Running a role multiple times in one play](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#running-a-role-multiple-times-in-one-play))
- 複数の group で使う role は、和集合のパターン (例: `hosts: webapp:terraform`) を対象にした play に置く ([Patterns](https://docs.ansible.com/ansible/latest/inventory_guide/intro_patterns.html))
- 和集合の play が増えすぎる場合は、一部のホストに不要な role が入ることを許容して、より広いパターンの play に寄せる
- role の実行順は play の単位でしか制御できない。先に実行したい role (パッケージマネージャの設定など) は前の play に置く

### OS の違い

OS の違い (Ubuntu / macOS など) は group では表さない。role の中で `ansible_facts.distribution` によって振り分ける。

## 運用手順

### inventory を用意する

実際のホスト名を公開リポジトリに含めないため、inventory の実ファイルは git 管理外にしている (`.gitignore` の `/inventories/*`)。commit するのは `inventories/localhost` と雛形の `inventories/*.example` だけ。

使う playbook に対応する雛形をコピーし、ホストを該当する group に書く。

```sh
cp inventories/workstation.example inventories/workstation
```

### ホスト上で clone して自身をセットアップする

該当する group に `localhost` を書く。ホスト名は不要。1 台のホストを複数の group に書いてよい。

```ini
[desktop]
localhost ansible_connection=local
[webapp]
localhost ansible_connection=local
```

```sh
poetry run ansible-playbook -i inventories/workstation playbook-workstation.yml
```

### リモートからセットアップする

実行する側のマシンの inventory に接続先を書く。playbook は同じものを使う。

```ini
[terraform]
tf-dev ansible_host=192.0.2.11
```

```sh
poetry run ansible-playbook -i inventories/workstation playbook-workstation.yml -K --limit terraform
```

- 対象ホストには SSH で接続でき、`python3` が入っていて、sudo が使えること (`-K` でパスワードを入力するか、NOPASSWD を設定する)
- ホスト名を inventory に書きたくない場合は、`~/.ssh/config` に別名を定義し、inventory には別名だけを書く
- 公開したくない group 変数は、git 管理外の `inventories/group_vars/` に置く ([Organizing host and group variables](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#organizing-host-and-group-variables))

### role を追加する

その role を使う group の組み合わせを対象にした play に追記する。該当する play がなければ追加する ([playbook の書き方](#playbook-の書き方))。

### group を追加する

1. [判断基準](#playbook-を分けるかgroup-を追加するかの判断基準) で、既存の playbook に group を追加すべきか確認する
2. `inventories/*.example` に group を追加し、用途をコメントで書く
3. playbook に、その group を対象にした play を追加する (または既存の play の `hosts:` に加える)
4. `molecule/*/molecule.yml` のいずれかの scenario で、コンテナをその group に所属させる

### playbook を追加する

1. [判断基準](#playbook-を分けるかgroup-を追加するかの判断基準) で、playbook を分けるべきか確認する
2. `playbook-<name>.yml` と、その playbook の group を定義した `inventories/<name>.example` を追加する
3. E2E テストの scenario を追加する

### E2E テスト (molecule)

molecule の scenario は、playbook ごとではなく、コンテナを所属させる group の組み合わせごとに分ける。1 つの playbook に対して、group の組み合わせを変えた scenario を複数用意してよい。

```sh
poetry run molecule test -s <scenario>
```
