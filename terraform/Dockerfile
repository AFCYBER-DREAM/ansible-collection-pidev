FROM ubuntu:18.04

ENV TF_VERSION 0.11.13
ENV TF_ANSIBLE_VERSION 2.2.0

RUN apt-get update && apt-get install -y curl git python3 python3-pip unzip

RUN pip3 install ansible==2.7

# Install Terraform
RUN curl https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip -o \
                                                          terraform_${TF_VERSION}.zip
RUN unzip terraform_${TF_VERSION}.zip
RUN mv terraform /usr/bin/terraform

# Install Terraform-Ansible
RUN git clone https://github.com/AFCYBER-DREAM/ansible-collection-pidev.git
RUN sed -i -e '1s/sh/bash/' ansible-collection-pidev/terraform/install-tf-ansible.sh

RUN ./ansible-collection-pidev/terraform/install-tf-ansible.sh -v ${TF_ANSIBLE_VERSION}

# Cleanup
RUN rm -r ansible-collection-pidev && rm terraform_${TF_VERSION}.zip

