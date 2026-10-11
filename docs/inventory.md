# playbook / host group の運用設計

## 役割の分担

| 仕組み | 表すもの | 例 |
|---|---|---|
| playbook | 環境の種類 | `playbook-workstation.yml` (作業用マシン)、`playbook-docker-service.yml` (サービス用サーバー) |
| inventory の group | 同じ playbook の中で、ホストを何に使うか | `desktop` / `webapp` / `devos` / `terraform` |
| tags | role 単位で実行を絞り込む | `--tags golang` |

OS の違い (Ubuntu / macOS など) は group では表さない。role の中で `ansible_facts.distribution` によって振り分ける。

### playbook を分けるか、group を追加するかの判断基準

「1 台のホストが両方に属することがあるか」で判断する。

- 属することがある → 同じ playbook の中で group を追加する
  - 例: macOS はデスクトップ兼開発機なので、`desktop` と `webapp` の両方に属する
- 属さない、または同じホストに適用すると衝突する → playbook を分ける
  - 同じ role を違うパラメータで使う (例: `playbook-gitlab.yml` は `NODEJS_MAJOR_VERSION: 8`、作業用マシンは 14)
  - 前提となる環境が違う (例: Kubernetes のノードは swap 無効、コンテナランタイムが必要)
  - ホストをまたいだ順序が必要 (例: control plane を初期化してから worker を参加させる)

1 台のホストは、1 つの playbook の group にだけ属させる。同じ role が複数の playbook に出てくるのは構わない (適用されるホストが重ならないため)。

## playbook-workstation.yml

### group

| group | 用途 | 主な role |
|---|---|---|
| `desktop` | GUI を使う作業用マシン (Ubuntu Desktop、macOS) | homenas_client, fluentd, dropbox |
| `devel` | 開発サーバー。下の 3 つの group の親 | apt, build-essential, nfs_client, docker |
| `webapp` | アプリケーション開発 | python, ruby, nodejs, yarn, rust, gcloud, terraform |
| `devos` | OS 開発 | (`devel` 共通の role のみ) |
| `terraform` | terraform 開発 | terraform, ansible |

`desktop` と `devel` の両方に共通する role (git, shell, ssh, fonts, aqua, golang) は `hosts: desktop:devel` の play で実行する。

ホストの割り当て例:

| ホスト | group |
|---|---|
| macOS (デスクトップ兼開発機) | `desktop`, `webapp` |
| Ubuntu Desktop (IDE まで。開発はリモートサーバーで行う) | `desktop` |
| 開発サーバー | `webapp` / `devos` / `terraform` のいずれか (複数可) |

### playbook の書き方

- group の制御は play の `hosts:` だけで行う。role に `when: "'webapp' in group_names"` のような group 判定は書かない
- 各 role は 1 つの play にだけ書く
  - Ansible が role の重複実行を省くのは同じ play の中だけ。別の play に同じ role を書くと、両方の group に属するホストでは 2 回実行される ([Running a role multiple times in one play](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#running-a-role-multiple-times-in-one-play))
- 複数の group で使う role は、和集合のパターン (例: `hosts: webapp:terraform`) を対象にした play に置く ([Patterns](https://docs.ansible.com/ansible/latest/inventory_guide/intro_patterns.html))
- 和集合の play が増えすぎる場合は、少し余分なホストに入ることを許容して、より広い play に寄せる
  - 例: golang は `devos` には不要だが、play を増やさないために `desktop:devel` の play に入れている
- role の実行順は play の単位でしか制御できない。先に実行したい role (apt など) は前の play に置く

### role / group を追加するとき

- role を追加する: その role を使う group の組み合わせに対応する play に追記する。対応する play がなければ追加する
- 用途を追加する: `inventories/workstation.example` に group を追加し、`hosts:` がその group を対象にする play を追加する。開発サーバー用の用途なら `devel:children` にも追加する
- 上の group の表とホストの割り当て例を更新する

## inventory の管理

このリポジトリは公開しているため、実際のホスト名は commit しない。

- `inventories/*` は git 管理外 (`.gitignore`)。commit するのは `inventories/localhost` と `inventories/*.example` だけ
- `inventories/workstation.example` を `inventories/workstation` にコピーし、実際のホストを書く

### ホスト上で clone して自身をセットアップする

該当する group に `localhost` を書く。ホスト名は不要。

```ini
# macOS (デスクトップ兼開発機)
[desktop]
localhost ansible_connection=local
[webapp]
localhost ansible_connection=local

[devel:children]
webapp
devos
terraform
```

```sh
poetry run ansible-playbook -i inventories/workstation playbook-workstation.yml
```

### リモートからセットアップする

実行する側のマシンの inventory に接続先を書く。playbook は同じものを使う。

```ini
[terraform]
tf-dev ansible_host=192.0.2.11

[devel:children]
webapp
devos
terraform

[devel:vars]
ansible_user=thaim
```

```sh
poetry run ansible-playbook -i inventories/workstation playbook-workstation.yml -K --limit terraform
```

- 対象ホストには SSH で接続でき、`python3` が入っていて、sudo が使えること (`-K` でパスワードを入力するか、NOPASSWD を設定する)
- ホスト名を隠したい場合は `~/.ssh/config` に別名を定義し、inventory には別名だけを書く
- 公開したくない group 変数は、git 管理外の `inventories/group_vars/` に置く ([Organizing host and group variables](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#organizing-host-and-group-variables))

## E2E テスト (molecule)

molecule の scenario は playbook ごとではなく、コンテナを所属させる group の組み合わせごとに分ける。

| scenario | コンテナを所属させる group |
|---|---|
| `molecule/desktop` | `desktop` |
| `molecule/devel` | `devel`, `webapp`, `devos`, `terraform` |

group を追加したら、いずれかの scenario に追加するか、scenario を新しく作る。

## 今後追加する予定の playbook

- `playbook-k8s.yml`: Kubernetes クラスタのノードのセットアップ
  - 判断基準から、作業用マシンとは playbook を分ける (前提となる環境が違い、ホストをまたいだ順序も必要なため)
  - group は `k8s_cluster` の下に `k8s_control_plane` / `k8s_worker` を置く。Kubespray のサンプル inventory と同じ考え方 ([kubespray inventory sample](https://github.com/kubernetes-sigs/kubespray/blob/master/inventory/sample/inventory.ini))
