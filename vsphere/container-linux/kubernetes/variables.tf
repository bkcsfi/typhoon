variable "cluster_name" {
  type        = "string"
  description = "Unique cluster name"
}

variable "domain_suffix" {
  type        = "string"
  description = "domain name suffix used by controllers etcd"
  default     = "example.com"
}

variable "vsphere_datacenter" {
  type        = "string"
  description = "vSphere datacenter name"
}

variable "vsphere_datastore" {
  type        = "string"
  description = "vSphere Datastore to place workers and controllers on"
}

variable "vsphere_resource_pool" {
  type        = "string"
  default     = "cluster/Resources"
  description = "vSphere Resource pool for controllers and workers"
}

variable "vsphere_network" {
  type        = "string"
  description = "vSphere network for controllers and workers"
}

variable "vsphere_folder" {
  type        = "string"
  default     = ""
  description = "vSphere folder to store cluster folder in"
}

variable "template_vm" {
  type        = "string"
  description = "Name of VM Template from which to initialize workers and controllers"
}

variable "controller_count" {
  type        = "string"
  default     = "1"
  description = "Number of controllers"
}

variable "controller_ip_addresses" {
  type        = "list"
  description = "list of controller ip addresses (overrides controller_count)"
}

variable "controller_dns_address" {
  type        = "string"
  description = "ip address of dns server for controllers"
}

variable "controller_gateway_ip_address" {
  type        = "string"
  description = "ip address of ipv4 gateway for controllers"
}

variable "controller_ip_subnet_bits" {
  type        = "string"
  description = "number of bits used by controller subnet"
  default     = "24"
}

variable "controller_cpu_count" {
  type        = "string"
  default     = "2"
  description = "Number of cpus to assign to controllers"
}

variable "controller_memory" {
  type        = "string"
  default     = "2048"
  description = "Amount of RAM to assign to controllers"
}

variable "controller_disk_size" {
  type        = "string"
  default     = ""
  description = "Size of controller disk (defaults to template_vm disk size)"
}

variable "worker_count" {
  type        = "string"
  default     = "1"
  description = "Number of workers"
}

variable "worker_cpu_count" {
  type        = "string"
  default     = "2"
  description = "Number of cpus to assign to workers"
}

variable "worker_memory" {
  type        = "string"
  default     = "2048"
  description = "Amount of RAM to assign to workers"
}

variable "worker_disk_size" {
  type        = "string"
  default     = ""
  description = "Size of worker disk (defaults to template_vm disk size)"
}

variable "ssh_authorized_key" {
  type        = "string"
  description = "SSH public key for user 'core' ssh-rsa AAAA"
}

# bootkube assets

variable "k8s_domain_name" {
  description = "Controller DNS name which resolves to a controller instance. Workers and kubeconfig's will communicate with this endpoint (e.g. cluster.example.com)"
  type        = "string"
}


variable "asset_dir" {
  description = "Path to a directory where generated assets should be placed (contains secrets)"
  type        = "string"
}

variable "networking" {
  description = "Choice of networking provider (flannel or calico)"
  type        = "string"
  default     = "calico"
}

variable "network_mtu" {
  description = "CNI interface MTU (applies to calico only)"
  type        = "string"
  default     = "1480"
}

variable "pod_cidr" {
  description = "CIDR IP range to assign Kubernetes pods"
  type        = "string"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  description = <<EOD
CIDR IP range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for kube-dns.
EOD

  type    = "string"
  default = "10.3.0.0/16"
}

variable "cluster_domain_suffix" {
  description = "Queries for domains with the suffix will be answered by kube-dns. Default is cluster.local (e.g. foo.default.svc.cluster.local) "
  type        = "string"
  default     = "cluster.local"
}

