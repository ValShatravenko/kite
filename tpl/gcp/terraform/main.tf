provider "google" {
  credentials = "${file("${var.credentials}")}"
  project = "${var.project}"
  region = "${var.region}"
}

# Allow SSH to Platform Bastion
resource "google_compute_firewall" "bastion" {
  name    = "bastion-rules"
  network = "${google_compute_network.platform.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["bastion"]
}

# Bastion host
resource "google_compute_address" "bastion" {
  name = "bastion-ip"
}

resource "google_compute_instance" "bastion" {
  name         = "bastion"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"

  tags = ["bastion", "platform-internal"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-8"
    }
  }

  metadata {
    sshKeys = "kite:${file(var.public_key)}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.platform_net.name}"
    access_config {
      nat_ip = "${google_compute_address.bastion.address}"
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}