FROM ubuntu:19.04


RUN apt-get update

ENV PYTHONIOENCODING=UTF-8

RUN apt-get update && \
    apt-get install -y \
    less \
    man \
    ssh \
    python \
    python-pip \
    python-virtualenv \
    vim \
    git \
    jq

RUN adduser --disabled-login --gecos '' aws
WORKDIR /home/aws

USER aws

RUN \
    mkdir aws && \
    virtualenv aws/env && \
    ./aws/env/bin/pip install awscli && \
    echo 'source $HOME/aws/env/bin/activate' >> .bashrc && \
    echo 'complete -C aws_completer aws' >> .bashrc

RUN git config credential.helper store

WORKDIR /home/aws/sogdian-infra/
