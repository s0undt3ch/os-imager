#!/bin/bash

if [ ! -d .tmp ]; then
    mkdir .tmp
fi

if [ ! -d .tmp/states ]; then
    mkdir .tmp/states
fi

if [ ! -d .tmp/pillar ]; then
    mkdir .tmp/pillar
    printf "base:\n  '*':\n    - docker-builds" > .tmp/pillar/top.sls
    printf "py$PY_VERSION: true\n" > .tmp/pillar/pillar/docker-builds.sls
fi

if [ -d .tmp/states/.git ]; then
    git fetch
    git -C .tmp/states reset --hard origin/$SALT_BRANCH
else
    git clone
    git clone --branch $SALT_BRANCH https://github.com/saltstack/salt-jenkins.git .tmp/states
fi
