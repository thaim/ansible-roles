ruby
=====

Description
---------------
rbenvを用いてrubyをインストールする．

- main.yml
  - required_libs_{{ ansible_facts.distribution }}.yml : 依存ライブラリのインストール
  - rbenv.yml : rbenvのインストール
  - ruby_{{ ansible_facts.distribution }}.yml : rubyのインストール
  - ruby_open_firewall.yml : 3000番ポートの開放(rails用途)
  - common.gems.yml : 共有gemのインストール(rails)



Variables
---------------
RUBY_VERSION: インストールするRubyのバージョン
RUBY_CONFIGURE_OPTS: ruby-build に渡す configure オプション (既定は `--disable-install-doc` でドキュメントを生成しない)

Support OS
---------------

- Ubuntu
- CentOS
