FROM ubuntu:18.04

USER root

RUN \
  apt-get update && \
  apt-get install -y software-properties-common && \
  apt-add-repository ppa:ansible/ansible && \
  apt-get update && \
  apt-get install -y --force-yes ansible=2.8.1-1ppa~bionic

RUN mkdir /ansible
WORKDIR /ansible