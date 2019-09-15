FROM centos:centos7
#https://docs.docker.com/engine/examples/running_ssh_service/

RUN yum install -y openssh-server
RUN mkdir /var/run/sshd

RUN yum install -y openssh-clients

#
# Could not load host key: /etc/ssh/ssh_host_rsa_key
# Could not load host key: /etc/ssh/ssh_host_ecdsa_key
# Could not load host key: /etc/ssh/ssh_host_ed25519_key
#  sshd: no hostkeys available -- exiting.
#
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

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

COPY ./startSSHAndCreateOptionallyUser.sh /bin/startSSHAndCreateOptionallyUser.sh

EXPOSE 22
ENTRYPOINT ["startSSHAndCreateOptionallyUser.sh"]