"""
各シェルの設定ファイルを返す。
/bin/bashなら ['bash', '.bashrc', '.bash_profile']、など。
"""

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


def get_shell_config(shell_path):
    shell_name = shell_path.split('/')[-1]
    if shell_name == 'bash':
        return {
            'name': 'bash',
            'rc_file': '.bashrc',
            'profile_path': '.bash_profile'
        }
    elif shell_name == 'zsh':
        return {
            'name': 'zsh',
            'rc_file': '.zshrc',
            'profile_path': '.zprofile'
        }
    # 他のシェルに対する設定をここに追加
    else:
        return {
            'name': shell_name,
            'rc_file': None,
            'profile_path': None
        }


class FilterModule(object):
    def filters(self):
        return {
            'shell_config': get_shell_config
        }
