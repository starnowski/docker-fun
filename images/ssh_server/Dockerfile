FROM ubuntu:16.04
#https://docs.docker.com/engine/examples/running_ssh_service/

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd

RUN apt-get -y install openssh-client

# Create user 'John'
RUN useradd -m -p Kent John

USER John

RUN mkdir -p /home/John/.ssh
RUN ssh-keygen -q -t rsa -N '' -f /home/John/.ssh/id_rsa
RUN cat /home/John/.ssh/id_rsa.pub >> /home/John/.ssh/authorized_keys


USER root
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

COPY ./printTestValue.sh /bin/printTestValue.sh

# Fixing problems with locale on Travis CI :
#
# bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)
#
#https://www.thomas-krenn.com/en/wiki/Perl_warning_Setting_locale_failed_in_Debian
RUN apt-get install -y locales
RUN locale-gen en_US.UTF-8

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]