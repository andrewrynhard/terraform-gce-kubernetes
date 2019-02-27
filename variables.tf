variable "gce_talos_img" {
  default = "talos"
}

variable "gce_talos_disk_size" {
  default = "10"
}

variable "gce_talos_flavor" {
  default = "g1-small"
}

variable "gce_talos_master_ips" {
	type = "list"
}

variable "talos_master_count" {
  default = 3
}

variable "talos_worker_count" {
  default = 2
}

variable "talos_cluster_name" {
  default = "talos-gce"
}
