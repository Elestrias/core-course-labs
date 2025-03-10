terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone = var.zone
}

resource "yandex_vpc_address" "vm1" {
  name = "vm1-devops"

  external_ipv4_address {
    zone_id = var.zone
  }
}

data "yandex_compute_image" "ubuntu-2204-lts" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_instance" "default" {
  name        = var.vm_name
  platform_id = "standard-v1"
  zone        = var.zone

  allow_stopping_for_update = true

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-2204-lts.image_id
    }
  }

  network_interface {
    subnet_id      = yandex_vpc_subnet.networkabobus.id
    nat_ip_address = yandex_vpc_address.vm1.external_ipv4_address[0].address
    nat            = true
  }

  hostname = var.hostname

  metadata = {
    serial-port-enable = 1
    ssh-keys           = "ubuntu:${file("~/.ssh/vmKey.pub")}"
  }
}

resource "yandex_vpc_network" "networkabobus" {}

resource "yandex_vpc_subnet" "networkabobus" {
  zone           = var.zone
  network_id     = yandex_vpc_network.networkabobus.id
  v4_cidr_blocks = ["10.228.0.0/24"]
}