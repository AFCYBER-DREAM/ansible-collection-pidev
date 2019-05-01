#
# Install virtual box plugin
#     git clone git@github.com:terra-farm/terraform-provider-virtualbox.git
#     cd terraform-provider-virtualbox
#     go build
#     mkdir -p ~/.terraform.d/plugins/
#     cp terraform-provider-virtualbox ~/.terraform.d/plugins
#
# 
# resource "virtualbox_vm" "node" {
#     count = 1
#     name = "${format("node-%02d", count.index+1)}"
#
#     url = "araulet/ubuntu1804-server-minimal"
#     cpus = 2
#     memory = "4gb"
#
#     network_adapter {
#         type = "nat"
#     }
#
#     network_adapter {
#         type = "bridged"
#         host_interface = "en0"
#     }
#
# }
#
# output "IPAddr" {
#     # Get the IPv4 address of the bridged adapter (the 2nd one) on 'node-02'
#     value = "${element(virtualbox_vm.node.*.network_adapter.1.ipv4_address, 1)}"
# }
