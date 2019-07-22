FROM ubuntu:18.04

USER root

RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y gcc wget
RUN cd /usr/src && wget https://www.python.org/ftp/python/2.7.16/Python-2.7.16.tgz && tar xzf Python-2.7.16.tgz
RUN apt-get install -y zlib1g-dev
#https://codeday.me/en/qa/20190306/12410.html
RUN apt-get install -y libssl-dev
RUN cd /usr/src/Python-2.7.16 && ./configure --enable-optimizations
RUN apt-get install -y make
RUN cd /usr/src/Python-2.7.16 && make altinstall
RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && python2.7 get-pip.py
RUN pip install ansible==2.8.1

RUN mkdir /ansible
WORKDIR /ansible