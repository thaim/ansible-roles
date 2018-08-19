python
====================


python venvはpythonの仮想開発環境．



# 仮想開発環境の選択
Pythonにおける仮想開発環境にはいくつかの選択肢が存在する

- virtualenv (venv, pyvenv)
  - ここで扱う仮想開発環境
  - 3.3以降はPythonに取り込まれてvenvという名前になった
  - pyvenvとも呼ばれていたが3.6以降は非推奨
- pyenv
  - 日本でよく利用される仮想開発環境
  - プラグインとしてvirtualenv/virtualenvwrapperなどがある
- pip
  - デファクトのパッケージ管理
- easy_install
  - 過去に存在したパッケージ管理ツール
- anaconda
  - pythonおよびパッケージ管理ツール
  - windows向け．linux向けでも利用できるがPATHの書き換えなどがあり扱いが難しい

# パッケージの管理
基本はpipで管理する．ただし，
グローバルパッケージとローカルパッケージ
を意識して切り分ける必要がある．

- グローバルパッケージ
  - 開発プロジェクトに依存せずすべてのユーザが利用するときに選択する
  - root権限でインストールする
- ローカルパッケージ
  - ~/.local/{bin,lib}にインストールされるパッケージ
  - 管理者権限不要だが指定ユーザでのみ有効
  - 開発プロジェクトに依存せずに利用するがユーザ単位で利用を決定したいときに選択する
  - --userオプションでインストールする
- 開発環境
  - 開発プロジェクトに応じて利用を決定したいときに選択する
  - requirements.txtで管理する