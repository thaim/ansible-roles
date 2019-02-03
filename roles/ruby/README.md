ruby
=====

Description
---------------
rbenvを用いてrubyをインストールする．

- main.yml
  - required_libs_{{ ansible_distribution }}.yml : 依存ライブラリのインストール
  - rbenv.yml : rbenvのインストール
  - ruby_{{ ansible_distribution }}.yml : rubyのインストール
  - ruby_open_firewall.yml : 3000番ポートの開放(rails用途)
  - common.gems.yml : 共有gemのインストール(rails)



Variables
---------------
RUBY_VERSION: インストールするRubyのバージョン

Support OS
---------------

- Ubuntu
- CentOS
