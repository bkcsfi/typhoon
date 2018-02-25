resource "vsphere_virtual_machine" "workers" {
  count = "${var.worker_count}"

  name   = "${var.cluster_name}-worker-${count.index}"
  resource_pool_id = "${data.vsphere_resource_pool.cluster_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.cluster_datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  

  tags = [
    "${vsphere_tag.workers.id}",
  ]

  enable_disk_uuid = true

  num_cpus = "${var.worker_cpu_count}"
  memory   = "${var.worker_memory}"

  guest_id  = "${data.vsphere_virtual_machine.cluster_template_vm.guest_id}"
  scsi_type = "${data.vsphere_virtual_machine.cluster_template_vm.scsi_type}"


  network_interface {
    network_id = "${data.vsphere_network.cluster_network.id}"
    adapter_type = "${data.vsphere_virtual_machine.cluster_template_vm.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${var.worker_disk_size != "" ? var.worker_disk_size : data.vsphere_virtual_machine.cluster_template_vm.disks.0.size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.cluster_template_vm.disks.0.eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.cluster_template_vm.disks.0.thin_provisioned}"    
  }

  clone {
    template_uuid    = "${data.vsphere_virtual_machine.cluster_template_vm.id}"
  }

  vapp {
    properties {
      "guestinfo.coreos.config.data" = "${element(data.ct_config.worker_ign.*.rendered, count.index)}"
    }
  }
}


# Tag to label controllers
resource "vsphere_tag" "workers" {
  name = "${var.cluster_name}-worker"
  category_id = "${vsphere_tag_category.category.id}"
}

# Worker Container Linux Config
data "template_file" "worker_config" {
  count = "${var.worker_count}"
  template = "${file("${path.module}/cl/worker.yaml.tmpl")}"

  vars = {
    domain_name = "${element(null_resource.repeat_worker.*.triggers.domain, count.index)}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    k8s_etcd_service_ip   = "${cidrhost(var.service_cidr, 15)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
    ssh_authorized_key      = "${var.ssh_authorized_key}"
  }
}

# Horrible hack to generate a Terraform list of a desired length without dependencies.
# Ideal ${repeat("worker", 3) -> ["worker", "worker", "worker"]}
resource null_resource "repeat_worker" {
  count = "${var.worker_count}"

  triggers {
    domain = "${var.cluster_name}-worker-${count.index}.${var.domain_suffix}"
  }
}

data "ct_config" "worker_ign" {
  count = "${var.worker_count}"
  content      = "${element(data.template_file.worker_config.*.rendered, count.index)}"
  pretty_print = false
}
