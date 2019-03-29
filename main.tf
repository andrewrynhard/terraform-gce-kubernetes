module "security" {
  source = "git::https://github.com/autonomy/terraform-talos-security"

  talos_target  = "${var.gce_talos_master_ips[0]}"
  talos_context = "${var.talos_cluster_name}"
}

module "configuration" {
  source = "github.com/autonomy/terraform-talos-configuration"

  "cluster_name"                       = "example"
  "trustd_password"                    = "${module.security.trustd_password}"
  "kubernetes_token"                   = "${module.security.kubeadm_token}"
  "kubernetes_certificate_key"         = "${module.security.kubeadm_certificate_key}"
  "kubernetes_ca_key"                  = "${module.security.kubernetes_ca_key}"
  "master_hostnames"                   = "${var.gce_talos_master_ips}"
  "pod_subnet"                         = "10.244.0.1/16"
  "talos_ca_crt"                       = "${module.security.talos_ca_crt}"
  "trustd_username"                    = "${module.security.trustd_username}"
  "kubernetes_ca_crt"                  = "${module.security.kubernetes_ca_crt}"
  "trustd_endpoints"                   = "${var.gce_talos_master_ips}"
  "container_network_interface_plugin" = "flannel"
  "service_subnet"                     = "10.96.0.1/12"
  "talos_ca_key"                       = "${module.security.talos_ca_key}"
}

resource "local_file" "admin_config" {
  depends_on = ["module.security"]
  content    = "${module.security.talos_admin_config}"
  filename   = "configs/admin.conf"
}

resource "google_compute_instance" "master_init_create" {
  name         = "${var.talos_cluster_name}-master-0"
  machine_type = "${var.gce_talos_flavor}"

  boot_disk {
    initialize_params {
      image = "${var.gce_talos_img}"
      size  = "${var.gce_talos_disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${var.gce_talos_master_ips[0]}"
    }
  }

  metadata {
    "user-data" = "${module.configuration.masters[0]}"
  }

  allow_stopping_for_update = true
}

resource "google_compute_instance" "master_join_create" {
  name         = "${var.talos_cluster_name}-master-${count.index + 1}"
  machine_type = "${var.gce_talos_flavor}"
  count        = "${var.talos_master_count - 1}"

  boot_disk {
    initialize_params {
      image = "${var.gce_talos_img}"
      size  = "${var.gce_talos_disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${var.gce_talos_master_ips[count.index + 1]}"
    }
  }

  metadata {
    "user-data" = "${module.configuration.masters[count.index + 1]}"
  }

  allow_stopping_for_update = true
}

resource "google_compute_instance" "worker_create" {
  name         = "${var.talos_cluster_name}-worker-${count.index}"
  machine_type = "${var.gce_talos_flavor}"
  count        = "${var.talos_worker_count}"

  boot_disk {
    initialize_params {
      image = "${var.gce_talos_img}"
      size  = "${var.gce_talos_disk_size}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    "user-data" = "${module.configuration.worker}"
  }

  allow_stopping_for_update = true
}
