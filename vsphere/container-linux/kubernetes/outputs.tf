
/*output "workers_dns" {
  value = "${vsphere_record.workers.0.fqdn}"
}
*/

output "controllers_ipv4" {
  value = ["${vsphere_virtual_machine.controllers.*.default_ip_address}"]
}


output "workers_ipv4" {
  value = ["${vsphere_virtual_machine.workers.*.default_ip_address}"]
}

output "controller_template" {
  value = "${data.ct_config.controller_ign.0.rendered}"
}