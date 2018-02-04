output "controllers_dns" {
  value = "${vsphere_record.controllers.0.fqdn}"
}

output "workers_dns" {
  value = "${vsphere_record.workers.0.fqdn}"
}

output "controllers_ipv4" {
  value = ["${vsphere_record.controllers.*.ipv4_address}"]
}

output "controllers_ipv6" {
  value = ["${vsphere_record.controllers.*.ipv6_address}"]
}

output "workers_ipv4" {
  value = ["${vsphere_record.workers.*.ipv4_address}"]
}

output "workers_ipv6" {
  value = ["${vsphere_record.workers.*.ipv6_address}"]
}
