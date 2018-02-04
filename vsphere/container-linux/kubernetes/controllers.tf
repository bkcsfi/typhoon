# Controller instances
resource "vsphere_record" "controllers" {
  count = "${var.controller_count}"

  name   = "${var.cluster_name}-controller-${count.index}"
  resource_pool_id = "${data.vsphere_source_pool.cluster_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.cluster_datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  

  user_data = "${element(data.ct_config.controller_ign.*.rendered, count.index)}"
  ssh_keys  = "${var.ssh_fingerprints}"

  tags = [
    "${vsphere_tag.controllers.id}",
  ]

  enable_disk_uuid = true

  num_cpus = "${var.controller_cpu_count}"
  memory   = "${controller_memory}"

  guest_id  = "${data.vsphere_virtual_machine.cluster_template_vm.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.cluster_template_vm.scsi_type}"


  network_interface {
    network_id = "${data.vsphere_network.cluster_network.id}"
    adapter_type = "${data.vsphere_virtual_machine.cluster_template_vm.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${var.controller_disk_size != '' ? var.controller_disk_size : data.vsphere_virtual_machine.cluster_template_vm.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.cluster_template_vm.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.cluster_template_vm.disks.0.thin_provisioned}"    
  }

  clone {
    template_uuid    = "${data.vsphere_virtual_machine.cluster_template_vm.id}"
  }

  vapp {
    properties {
       "guestinfo.coreos.config.data" = "${element(data.ct_config.controller_ign.*.rendered, count.index)}"
       "guestinfo.coreos.config.data.encoding" = "base64"
#      "guestinfo.hostname"                        = "basic-test.strader-ferris.com"
      "guestinfo.interface.0.name"                = "ens192"
#      "guestinfo.interface.0.ip.0.address"        = "10.0.0.100/24"
#      "guestinfo.interface.0.route.0.gateway"     = "10.0.0.1"
#      "guestinfo.interface.0.route.0.destination" = "0.0.0.0/0"
#      "guestinfo.dns.server.0"                    = "10.0.0.10"
    }
  }  

  # user_data = "${element(data.ct_config.controller_ign.*.rendered, count.index)}"
  # ssh_keys  = "${var.ssh_fingerprints}"

}

resource "vsphere_folder" "folder" {
  path          = "${join('/', [var.vsphere_folder, var.cluster_name])}"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Tag to label controllers
resource "vsphere_tag" "controllers" {
  name = "${var.cluster_name}-controller"
}

# Controller Container Linux Config
data "template_file" "controller_config" {
  count = "${var.controller_count}"

  template = "${file("${path.module}/cl/controller.yaml.tmpl")}"

  vars = {
    # Cannot use cyclic dependencies on controllers or their DNS records
    etcd_name   = "etcd${count.index}"
    etcd_domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"

    # etcd0=https://cluster-etcd0.example.com,etcd1=https://cluster-etcd1.example.com,...
    etcd_initial_cluster  = "${join(",", formatlist("%s=https://%s:2380", null_resource.repeat.*.triggers.name, null_resource.repeat.*.triggers.domain))}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
    ssh_authorized_key      = "${var.ssh_authorized_key}"
  }
}

# Horrible hack to generate a Terraform list of a desired length without dependencies.
# Ideal ${repeat("etcd", 3) -> ["etcd", "etcd", "etcd"]}
resource null_resource "repeat" {
  count = "${var.controller_count}"

  triggers {
    name   = "etcd${count.index}"
    domain = "${var.cluster_name}-etcd${count.index}.${var.dns_zone}"
  }
}

data "ct_config" "controller_ign" {
  count        = "${var.controller_count}"
  content      = "${element(data.template_file.controller_config.*.rendered, count.index)}"
  pretty_print = false
}
