// get id values for resources such as datastore, network and folder
data "vsphere_datacenter" "cluster_datacenter" {
    name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "cluster_datastore" {
    name = "${var.vsphere_datastore}"
    datacenter_id   = "${data.vsphere_datacenter.cluster_datacenter.id}"
}

data "vsphere_source_pool" "cluster_resource_pool" {
    name = "${var.vsphere_resource_pool}"
    datacenter_id   = "${data.vsphere_datacenter.cluster_datacenter.id}"
}

data "vsphere_network" "cluster_network" {
    name = "${var.vsphere_network}"
    datacenter_id   = "${data.vsphere_datacenter.cluster_datacenter.id}"
}

data "vsphere_folder" "cluster_folder" {
    name = "${var.vsphere_folder}"
    datacenter_id   = "${data.vsphere_datacenter.cluster_datacenter.id}"
}

data "vsphere_virtual_machine "cluster_template_vm" {
    name = "${var.template_vm}"
    datacenter_id   = "${data.vsphere_datacenter.cluster_datacenter.id}"
}
