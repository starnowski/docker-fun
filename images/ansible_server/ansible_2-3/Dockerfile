FROM centos:centos7

USER root

RUN yum install -y gcc openssl-devel bzip2-devel wget
RUN cd /usr/src && wget https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz && tar xzf Python-2.7.16.tgz
RUN cd /usr/src/Python-2.7.16 && ./configure --enable-optimizations
RUN yum -y install make
RUN cd /usr/src/Python-2.7.16 && make altinstall

RUN mkdir /ansible
WORKDIR /ansible