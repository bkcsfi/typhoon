# Controller instances
resource "vsphere_virtual_machine" "controllers" {
  count = "${var.controller_count}"

  name   = "${var.cluster_name}-controller-${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.cluster_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.cluster_datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  

  tags = [
    "${vsphere_tag.controllers.id}",
  ]

  enable_disk_uuid = true

  num_cpus = "${var.controller_cpu_count}"
  memory   = "${var.controller_memory}"

  guest_id  = "${data.vsphere_virtual_machine.cluster_template_vm.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.cluster_template_vm.scsi_type}"


  network_interface {
    network_id = "${data.vsphere_network.cluster_network.id}"
    adapter_type = "${data.vsphere_virtual_machine.cluster_template_vm.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${var.controller_disk_size != "" ? var.controller_disk_size : data.vsphere_virtual_machine.cluster_template_vm.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.cluster_template_vm.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.cluster_template_vm.disks.0.thin_provisioned}"    
  }

  clone {
    template_uuid    = "${data.vsphere_virtual_machine.cluster_template_vm.id}"
  }

  vapp {
    properties {
      "guestinfo.coreos.config.data" = "${element(data.ct_config.controller_ign.*.rendered, count.index)}"
      "guestinfo.coreos.config.data.encoding" = ""
      "guestinfo.hostname"                        = "${element(null_resource.repeat.*.triggers.domain, count.index)}"
    }
  }  
}


resource "vsphere_folder" "folder" {
  path          = "${join("/", list(var.vsphere_folder, var.cluster_name))}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.cluster_datacenter.id}"
}

resource "vsphere_tag_category" "category" {
  name        = "typhoon-k8s-category"
  cardinality = "MULTIPLE"
  description = "Typhoon Kubernetes Management Tag"

  associable_types = [
    "VirtualMachine",
    "Folder"
  ]
}

# Tag to label controllers
resource "vsphere_tag" "controllers" {
  name = "${var.cluster_name}-controller"
  category_id = "${vsphere_tag_category.category.id}"
}

# controller ip address
resource null_resource "controller_ip_address" {
  count = "${var.controller_count}"
  triggers = {    
    ip_address = "${element(var.controller_ip_addresses,count.index)}"
  }
}

# Controller Container Linux Config
data "template_file" "controller_config" {
  count = "${var.controller_count}"

  template = "${file("${path.module}/cl/controller.yaml.tmpl")}"

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    domain_name = "${element(null_resource.repeat.*.triggers.domain, count.index)}"
    etcd_domain = "${var.cluster_name}-etcd${count.index}.${var.domain_suffix}"
    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster  = "${join(",", formatlist("%s=https://%s:2380", null_resource.repeat.*.triggers.name, null_resource.repeat.*.triggers.domain))}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
    ssh_authorized_key      = "${var.ssh_authorized_key}"
    ip_address  = "${element(null_resource.controller_ip_address.*.triggers.ip_address, count.index)}"
  }
}

# Horrible hack to generate a Terraform list of a desired length without dependencies.
# Ideal ${repeat("etcd", 3) -> ["etcd", "etcd", "etcd"]}
resource null_resource "repeat" {
  count = "${var.controller_count}"

  triggers {
    name   = "etcd${count.index}"
    domain = "${var.cluster_name}-etcd${count.index}.${var.domain_suffix}"
  }
}

data "ct_config" "controller_ign" {
  count        = "${var.controller_count}"
  content      = "${element(data.template_file.controller_config.*.rendered, count.index)}\n${element(data.template_file.controller_network_config.*.rendered, count.index)}"
  pretty_print = false
}

data "template_file" "controller_network_config" {
#  count = "${var.controller_count}"
  count = "${var.controller_count}"

  template = <<EOF
networkd:
  units:
    - name: 00-eth0.network
      contents: |
        [Match]
        Name=ens192

        [Network]
        DNS=$${controller_dns_address}
        Address=$${ip_address}/$${controller_ip_subnet_bits}
        Gateway=$${controller_gateway_ip_address}
EOF

  vars = {
    ip_address  = "${element(null_resource.controller_ip_address.*.triggers.ip_address, count.index)}"
    controller_ip_subnet_bits = "${var.controller_ip_subnet_bits}"
    controller_gateway_ip_address = "${var.controller_gateway_ip_address}"
    controller_dns_address = "${var.controller_dns_address}"
  }
}

resource "null_resource" "export_rendered_template" {
  provisioner "local-exec" {
    command = "cat > /tmp/controller-test.txt <<EOL\n${data.ct_config.controller_ign.0.rendered}\nEOL"
  }
}