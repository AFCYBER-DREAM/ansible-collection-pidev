#!/usr/bin/env bash

# Ensure script is run as root user
# This script is designed to run strictly on clean development infrastructure, not production environments
if [[ "${EUID}" != "0" ]]; then
  echo "Must run with root user.";
  exit 1;
fi

pidevUsage() {
  echo "Usage: bootstrap.sh for pidev"
  echo "       [-e devenv_name]"
  echo "       [-o org_name]"
  echo "       [-r repo_name]"
  echo "       [-b repo_branch]"
  echo "       [-u]"
  echo "       [-p]"
  echo "       [-v]"
  echo "       [-h]"
  echo "       " 
  echo "       Optional Parameter(s):"
  echo "       -e:  Specifies development environment."
  echo "            (Default: ubuntu1804/dockerswarm+openfaas)"
  echo "       -o:  Sets org/username string of desired Github URL."
  echo "            (Default: afcyber-dream)"
  echo "       -r:  Sets repo name string of desired Github URL."
  echo "            (Default: ansible-collection-pidev)"
  echo "       -b: Sets the branch name of the repo."
  echo "            (Default: master)"
  echo "       -u:  Upgrades system deb/rpm packages on system."
  echo "            (Default: false)"
  echo "       -p:  Installs both 2.x and 3.x versions of Python."
  echo "            (Default: false)"
  echo "       -v:  Verbose mode; runs ansible commands with -vv."
  echo "            (Default: false)"
  echo "       -h:  Prints this help/usage message."
}

# Bash-builtin getopts is used to perform parsing, so no long options are used.
while getopts ":e:o:r:b:upvh" passed_parameter; do
 case "${passed_parameter}" in
    e)
      # Sanitizes the devenv string of space or any other undesired characters.
      requested_devenv_name="${OPTARG}";
      devenv_name="${requested_devenv_name//[^a-zA-Z0-9_+-]}";
      if [[ "${requested_devenv_name}" != "${devenv_name}" ]]; then
        echo "Requested devenv_name contains invalid characters; exiting." 2>&1;
        exit 1;
      fi
      ;;
    o)
      # Sanitizes the org/user name of space or any other undesired characters.
      requested_org_name="${OPTARG}";
      org_name="${requested_org_name//[^a-zA-Z0-9_-]}";
      if [[ "${requested_org_name}" != "${org_name}" ]]; then
        echo "Requested org_name contains invalid characters; exiting." 2>&1;
        exit 1;
      fi
      ;;
    r)
      # Sanitizes the repo name of spaces or any other undesired characters.
      requested_repo_name="${OPTARG}";
      repo_name="${requested_repo_name//[^a-zA-Z0-9_-]}";
      if [[ "${requested_repo_name}" != "${repo_name}" ]]; then
        echo "Requested repo_name contains invalid characters; exiting." 2>&1;
        exit 1;
      fi
      ;;
   b)
     # Sanitizes the branch name of space or any other undesired characters.
     requested_repo_branch="${OPTARG}";
     repo_branch="${requested_repo_branch//[^a-zA-Z0-9_+-]}";
     if [[ "${requested_repo_branch}" != "${repo_branch}" ]]; then
       echo "Requested repo_branch contains invalid characters; exiting." 2>&1;
   	exit 1;
     fi
     ;;
    u)
      # Used to toggle on system package upgrades during bootstrap
      upgrade="true";
      ;;
    p)
      # Used to toggle on install of non-default python major version during bootstrap
      both_pythons="true";
      ;;
    v)
      # Used to toggle on ansible verbosity during devenv configuration
      verbose="true";
      ;;
    h)
      # Help option; prints usage message, then returns 0
      pidevUsage;
      exit 0;
      ;;
    *)
      # Invalid option; prints usage message, then returns 1
      pidevUsage;
      exit 1;
      ;;
  esac
done;
shift $((OPTIND-1));

devenv_name="${devenv_name:=ubuntu1804/dockerswarm+openfaas}";
org_name="${org_name:=afcyber-dream}";
repo_name="${repo_name:=ansible-collection-pidev}";
upgrade="${upgrade:=false}";
both_pythons="${both_pythons:=false}";
verbose="${verbose:=false}";

# Validates development environment name and sets default pip version passed to ansible-pull
case "${devenv_name}" in
  ubuntu1804/dockerswarm+openfaas)
    default_pip="pip3";
    default_python="python3";
    ;;
  ubuntu1804/kind+ofc)
    default_pip="pip3";
    default_python="python3";
    ;;
  centos7/minishift)
    default_pip="pip2";
    default_python="python2";
    ;;
  *)
    echo "Bad devenv (${devenv_name}) specified.";
    pidevUsage;
    exit 1;
    ;;
esac

# Sets verbose flags (if applicable) used by ansible-pull
if [[ "${verbose}" == "true" ]]; then
  ansible_verbosity="-vv";
  bash_verbosity="set -x";
else
  ansible_verbosity="";
  bash_verbosity="";
fi

# Install system and python packages based on user-passed options
${bash_verbosity}
if [[ ${devenv_name} =~ ubuntu1804/* ]]; then
  apt-get update -y;
  if [[ ${upgrade} == "true" ]]; then
    apt-get upgrade -y;
  fi
  apt-get install -y curl git python3 python3-dev python3-pip;
  if [[ ${both_pythons} == "true" ]]; then
    apt-get install -y python2.7 python2.7-dev;
  fi
elif [[ ${devenv_name} =~ centos7/* ]]; then
  if [[ ${upgrade} == "true" ]]; then
    yum update -y
  fi
  yum install -y epel-release \
  && yum install -y centos-release-scl \
  && yum install -y curl git python2 python2-devel python2-pip;
  if [[ "${both_pythons}" == "true" ]]; then
    yum install -y rh-python36 rh-python36-python-devel rh-python36-python-pip;
    source /opt/rh/rh-python36/enable;
  fi
else
  echo "Unsupported pidev environment nickname; exiting..."
  exit 1;
fi

# Install ansible and docker python modules
${default_pip} install -U ansible==2.7 docker;

# Check to ensure repo URL is valid before proceeding to ansible-pull
repo_status_code="$(read _ status _ < <(curl -ksI https://github.com/${org_name}/${repo_name}); echo ${status})";
if [[ "${repo_status_code}" == "200" ]]; then
  ansible-pull \
    ${ansible_verbosity} \
    -i localhost, \
    -e "pidev_env_nickname=${devenv_name}" \
    -e "ansible_python_interpreter=${default_python}" \
    -U "https://github.com/${org_name}/${repo_name}.git" \
	--checkout "${repo_branch:-master}" \
    configure.yml;
else
  echo "Invalid repository URL; exiting..."
  exit 1;
fi
