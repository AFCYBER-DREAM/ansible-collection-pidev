#!/usr/bin/env bash

# Ensure script is run as root user
if [[ "${EUID}" != "0" ]]; then
  echo "Must run with root user.";
  exit 1;
fi

pidevUsage() {
  echo "Must pass Github org/repo (i.e. afcyber-dream/ansible-collection-pidev) as first arg to this script.";
  echo "Must pass one of the following as the second arg to this script:";
  echo "  - centos7/minishift";
  echo "  - ubuntu1804/dockerswarm+openfaas";
  echo "  - ubuntu1804/kind+ofc";
}

# Ensure script is passed appropriate number of args/parameters
if [[ "$#" != "2" ]]; then
  pidevUsage;
fi

# Determine development env name
case $2 in
  ubuntu1804/dockerswarm+openfaas)
    devenv_name="$2";
    ;;
  ubuntu1804/kind+ofc)
    devenv_name="$2";
    ;;
  centos7/minishift)
    devenv_name="$2";
    ;;
  *)
    pidevUsage;
    exit 1;
    ;;
esac

if [[ ${devenv_name} =~ ubuntu1804/* ]]; then
  apt-get install -y python3-pip;
  _python=$(which python3)
  _pip=pip3
elif [[ ${devenv_name} =~ centos7/* ]]; then

  yum install -y epel-release \
  && yum install -y centos-release-scl \
  && yum install -y git python27-python-pip \
  && yum install -y rh-python36 rh-python36-python-devel rh-python36-python-pip;
  # source /opt/rh/rh-python36/enable;
  _python=$(which python2.7)
  $_pip=pip
else
  echo "Unsupported pidev environment nickname; exiting..."
  exit 1;
fi

$_pip install -U ansible==2.7 docker;
repo_status_code="$(read _ status _ < <(curl -ksI https://github.com/$1); echo ${status})";
if [[ "${repo_status_code}" == "200" ]]; then
  ansible-pull -vv -U "https://github.com/$1.git" configure.yml -e "pidev_env_nickname=${devenv_name}" -e ansible_python_interpreter=${_python};
else
  echo "Invalid repository ($1) specified; exiting..."
  exit 1;
fi
