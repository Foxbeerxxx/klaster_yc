resource "yandex_kubernetes_node_group" "nodes" {
  cluster_id = yandex_kubernetes_cluster.k8s.id
  name       = "k8s-node-group"

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores  = 2
      memory = 4
    }

    boot_disk {
      type = "network-ssd"
      size = 50
    }

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.public_a.id]
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
    }
  }

  scale_policy {
    auto_scale {
      min     = 3
      max     = 6
      initial = 3
    }
  }

  allocation_policy {
    location { zone = "ru-central1-a" }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }

  depends_on = [yandex_kubernetes_cluster.k8s]
}

output "k8s_nodegroup_id" {
  value = yandex_kubernetes_node_group.nodes.id
}
