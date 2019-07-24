# ansible-collection-pidev

## Purpose

This repository contains the code required to setup various development/test environments used to test changes to Piper CI.

## Basic Usage

### Repository Selection

The first step is to decide whether you would like to use the code, as is, in the afcyber-dream/ansible-collection-pidev repo,
or alternately, fork the repo into your own organization. Currently, only www.github.com repositories are supported.

### Environment Selection

The next step is to decide which development environment you require.
This repository can be used to build several different development environments:

#### centos7/minishift

This environment is used to test application integration with `minishift` and `apb`.

#### ubuntu1804/dockerswarm+openfaas

This environment is used to test faas integration with `openfaas` installed atop `docker swarm`.

#### ubuntu1804/kind+ofc

Work in progress !

This environment is used to test faas integration with `openfaas cloud` installed atop `kind`.

### Environment Provisioning

Two supported options push with terraform or pull with a bootstra.sh script.

push is good for dev or managing infra with terraform, pull is good for CI/CD and docker image builds etc.

#### Terraform or "Push" Method

Current supported infra deploys by terraform
 - ubuntu1804/dockerswarm+openfaas

You can use Terraform to build a dev faas infra and push local developed faas functions.

##### Initial Deployment with Terraform to Digitial Ocean cloud

###### Configure Terraform

Install Ansible
`pip3 install ansible==2.7`

Configure your terraform.tfvars file with your key hash, username and digital ocean API key. See terraform/terraform.tfvars.example

Install the tf ansible plugin

`bash install-tf-ansible.sh`

```
-rwxr-xr-x  1 nickshobe  staff  31366360 May  7 14:03 /Users/myusername/.terraform.d/plugins/terraform-provisioner-ansible_v2.2.0
```

`terraform init`

```
Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "null" (2.1.2)...
- Downloading plugin for provider "digitalocean" (1.2.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.null: version = "~> 2.1"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

###### Run Terraform
From `terraform/` run `terraform apply`

##### Deploy faas functions from a local directory

Define your local faas function dir in `roles/ansible-role-pidev/defaults/main.yml`
```
pidev_piperci_faas:
...
  - name: piperci-gman-faas
    org_name: afcyber-dream
    method: copy
    src: "{{ lookup('env','HOME') }}/piperci-gman-faas/"
...
```

##### Run Terraform

`terraform apply -var tags=piperci_faas`

#### Manual deploy or "Pull" Method

Prior to using the code in your selected repository, a fresh/unmodified operating system is required.
The distro and version must match the one specified for the environment you wish to provision.
The environment can either be a virtual machine or dedicated machine, hosted anywhere internet accessible.

The "centos7/minishift" environment's operating system and host operating system (if a vm) must support nested virtualization.
DigitalOcean currently supports this in NYC1 and NYC3, but not in any other of it's datacenters.

#### Environment Configuration

You are going to be passing zero or more arguments to a bootstrap script in order to build your environment. If you decided to use the Terraform provisioner, this step will have already been performed for you. If you did not use the Terraform provisioner, after provisioning the instance some other way, login as the `root` user, and build/run your bootstrap command like below. First, you'll want to be aware of what options the bootstrap command has. It accepts zero or more option, and has a preset default for each one.

```
Usage: bootstrap.sh for pidev
       [-e devenv_name]
       [-o org_name]
       [-r repo_name]
       [-u]
       [-p]
       [-v]
       [-h]
       
       Optional Parameter(s):
       -e:  Specifies development environment.
            (Default: ubuntu1804/dockerswarm+openfaas)
       -o:  Sets org/username string of desired Github URL.
            (Default: afcyber-dream)
       -r:  Sets repo name string of desired Github URL.
            (Default: ansible-collection-pidev)
       -u:  Upgrades system deb/rpm packages on system.
            (Default: false)
       -p:  Installs both 2.x and 3.x versions of Python.
            (Default: false)
       -v:  Verbose mode; runs ansible commands with -vv.
            (Default: false)
       -h:  Prints this help/usage message.
```

Next, you'll want to build out your bootstrap command and run it. Below is a simple example of building out a command to run against your fork, while upgrading system packages. It is assumed in this example, that the name of your fork matches the name of the upstream repository. It is also assumed that you wish to use the default environment (ubuntu1804/dockerswarm+openfaas).

```
org="your-org-or-username-here"; bash <(curl -s https://raw.githubusercontent.com/${org}/ansible-collection-pidev/master/bootstrap.sh) -u -o ${org}
```

Running these commands will begin running a `bootstrap.sh` script that will provision your environment based on the environment requested.
After performing the steps neccessary to bootstrap `ansible`, the shell script will call an ansible playbook from the Github org/repo combo you passed it.
Monitor the output of this `ansible-playbook` run to determine when the environment has been fully provisioned. By default, the `pidev` user will be the user designed to use all the appliactions provisioned on the operating system. This user name, (and many other configuration options), can be changed. See the "Customizing Configuration Script" section for more details.

### Environment Resource Access

#### ubuntu1804/dockerswarm+openfaas

This environment is provisioned on an Ubuntu 18.04 LTS server, and includes a regular openfaas installation installed atop docker swarm. This provides a quick POC install of openfaas without all the multi-tenancy, and other bells and whistles provided by the kubernetes-installed openfaas cloud. It is great for performing integration testing of one or more faas functions as part of a CI pipeline.

No special client-side configuration is required to use access this particular environment. Once it has finished deploying, you simply access it here:

http://${server_ip}:8080/ui/

The docker swarm networking orchestrator is configured to proxy you to the backend API endpoint for each function, as well as the GUI for openfaas itself. From there, you can use the GUI to manually test/deploy your functions. By default, the configuration script installs from the master branches of the "afcyber-dream" repositories. The current list of installed functions can be found inside the repository your bootstrap script performed the `ansible-pull` command from. It should be located in `/root/.ansible/pull/`. The default repositories are listed in `defaults/ubuntu1804/dockerswarm+openfaas.yml`. See the "Customizing Configuration Script" section for details on how to modify these variables to add in custom functions you are writing. The configuration script is reasonably idempotent, and can be rerun to install new functions without negatively impacting the current running functions.


If you ssh into the server, you will have access to the `faas-cli` while logged into either the root or `pidev` user. This installation of the `faas-cli` can be used to invoke functions to test them. Alternately, you can use the curl-pipe-to-bash script provided by the faas-cli maintainers to install it on a different machine. See the `faas-cli` documentation if you would like to take that route, or just use the install provided on your server via the configuration script.

#### centos7/minishift

The minishift environment is provisioned inside of a virtual machine, so a SOCKS5 proxy between your local machine and the development environment is required in order to access some of it's resources. If your local machine is running a Debian-based Linux distribution, one way of setting this up is by performing the following steps:

```
# Install the firefox web browser
apt-get install firefox;

# Go to the extensions menu and install FoxyProxy Standard
firefox https://addons.mozilla.org/en-US/firefox/addon/foxyproxy-standard/

# Secure shell into the machine, passing the "-D" flag to setup a proxy on the desired local port
# Pro tip 1: Set an alias for the comand
alias minishift_proxy="ssh -D 6969 root@${server_ip}"; minishift_proxy

# Go into your FoxyProxy settings and set your traffic to proxy through 127.0.0.1:6969 (or whatever port you connected with above).

# You should now be able to access minishift at the 192.168.X.X address it is bound to on the virbr network on the server.
# If you don't know what address this is or the login information, run this to display it:
minishift stop; minishift start;

# The OpenShift web GUI should now be accessible via your local machine's web browser.
# Since the cert is self-signed, you may need to allow an exception for the self-signed cert in Firefox
firefox https://192.168.X.X:8443/console

# The apb command used to setup ansible playbook bundles on openshift, should be installed and accessible in the pidev user's path
su pidev;
which apb;

```

If you do not wish to install Firefox, FoxyProxy, or have some other reason to avoid modifications to your local machine, X11 forwarding is also an option. This can even be performed via a Windows desktop machine, assuming you have the `xming` package installed that will allow your Windows machine to understand the X11 graphical messages sent by the Linux server hosting the development environment.

```
# First, ensure you have `xming` and `putty` or `git bash` installed on your windows machine. The Windows Sub-system for Linux (WSL) or most other SSH emulators should work as well.

# Next, you will need to connect to your development server, ensuring you pass the "-Y" flag to toggle on X11 forwarding.
ssh -Y root@${server_ip};

# Now, on the command line of the server, ensure firefox is installed, and if not, install it.
which firefox || yum install firefox;

# Once installed, execute firefox over the command line on the server. You should see a X11 forwarded Firefox window displayed on your local machine
firefox https://192.168.X.X:8443/console

# This method is a bit slower than the SOCKS5 proxy method, so be prepared for a bit of lag as you are using the mouse or typing in Firefox
```

## Customizing Configuration Script

The code in this repository does not require any modifications in order to work as a quick-start instance; however, those familiar with `ansible` may wish to modify it.
This can be done by adding a "vars_file" to the `configure.yml` playbook and overriding variables defined in the `defaults/` directory of the role. Keep in mind, overriding any single variable dictionary completely overrides the contents of that single variable dictionary, as it appears in the `defaults/` directory; it does NOT merge your custom dictionary with that one.

The default variables are split between `defaults/main.yml` and `defaults/${env}.yml`. Please review these two locations to determine the variable dictionary structures before overriding the dictionary that is required to make your desired configuration change. You can see which environments use which variable dictionaries by reviewing the role's `tasks/main.yml` entry. This file contains a list of each tasks block called to build each environment.

The tasks blocks are located in `tasks/${tasks_block}.yml` and are divided in a way that lets groupings of tasks be reused by multiple different types of environments. Some tasks blocks use the same variables, regardless of the underlying environment, while other tasks blocks may use different variables, depending on the underlying environment. See each individual tasks block file to determine which one is the case for each task.
