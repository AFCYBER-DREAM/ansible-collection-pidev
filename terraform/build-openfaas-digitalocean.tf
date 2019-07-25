# Installation
#   Run ./install-tf-ansible.sh -v 2.2.0

variable "do_token" {}
variable "do_keys" { default = [] }
variable "tags" { default = "" }
variable "user" { default = "somedude" }
variable "run_provisioner" { default = true }

# Configure the DigitalOcean Provider
# set do_token = "your api acces token" in terrafrom.tfvars
provider "digitalocean" {
  version = "~> 1.2"
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "openfaas" {
  image  = "ubuntu-18-04-x64"
  name   = "openfaas-1-${var.user}"
  region = "nyc1"
  size   = "s-1vcpu-2gb"
  ssh_keys = "${var.do_keys}"

}

# Rerun provisioners on clean resources with null_resource
resource "null_resource" "ansible_config" {
  count = "${var.run_provisioner ? 1 : 0}"

  triggers {
    rerun = "${uuid()}"
  }

  # Bootstrap script can run on any instance of the openfaas droplet
  # So we just choose the first in this case
  connection {
    host = "${element(digitalocean_droplet.openfaas.*.ipv4_address, 0)}"
  }

  provisioner "ansible" {
    plays {
      playbook = {
        file_path = "../configure.yml"
        roles_path = ["../roles"]
        # tags = [ "${var.tags}" ]
      }
      # shared attributes
      enabled = true

      extra_vars = {
        ansible_python_interpreter = "python3"
        pidev_env_nickname = "ubuntu1804/dockerswarm+openfaas"
      }
    }
  }
}

output "IPAddress" {
  # Get the IPv4 addresses
  value = "${digitalocean_droplet.openfaas.ipv4_address}"
}

output "OpenFaas_URI" {
  value = "http://${digitalocean_droplet.openfaas.ipv4_address}:8080/ui/"
  description = "OpenFaas Service URI"
  depends_on = [
    # Only output the openfaas info if the ansible configs ran successfully
    "null_resource.ansible_config",
  ]
}
