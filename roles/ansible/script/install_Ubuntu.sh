#!/bin/bash

add-apt-repository -y ppa:ansible/ansible
apt-get update
apt-get install -y ansible
