FROM centos:centos7

USER root

RUN yum install -y gcc openssl-devel bzip2-devel wget make
RUN cd /usr/src && wget https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz && tar xzf Python-2.7.16.tgz
#https://codeday.me/en/qa/20190306/12410.html
RUN cd /usr/src/Python-2.7.16 && ./configure --enable-optimizations
RUN cd /usr/src/Python-2.7.16 && make altinstall
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && python2.7 get-pip.py
RUN pip install ansible==2.8.1

#Install ssh client
RUN yum install -y openssh-clients

RUN mkdir /ansible
WORKDIR /ansible