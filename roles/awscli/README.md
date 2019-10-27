aws cli
==============================

Install aws cli and related tools.

## list of cli/tools

cli

* [aws cli](https://github.com/aws/aws-cli)
* [aws EB CLI](https://pypi.org/project/awsebcli/)
* [aws ecs cli](https://github.com/aws/amazon-ecs-cli)

useful configurations

* [git secrets](https://github.com/awslabs/git-secrets)

## Usage

Install awscli only
```
- { role: awscli, tags: awscli }
```


Install awscli and all other cli tools
```
- { role: awscli, tags: awscli, AWSCLI_OPTION: 'all' }
```


## Variables

* **AWSCLI_OPTION**
  * **all**: install all cli tools
  * **simple**: install awscli only (default)
  * **select**: isntall specified cli tools
* **AWSCLI_OPTION_FARGATECLI**
  * install [awslabs/fargatecli](https://github.com/awslabs/fargatecli)
