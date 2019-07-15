FROM centos:centos7

USER root

RUN yum install -y gcc openssl-devel bzip2-devel wget
RUN cd /usr/src && wget https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz && tar xzf Python-2.7.16.tgz
RUN cd /usr/src/Python-2.7.16 && ./configure --enable-optimizations
RUN yum -y install make
RUN cd /usr/src/Python-2.7.16 && make altinstall
RUN yum -y install epel-release
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && python2.7 get-pip.py
RUN pip install ansible==2.3.3.0

RUN mkdir /ansible
WORKDIR /ansible