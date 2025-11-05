resource "yandex_kubernetes_cluster" "k8s" {
  name        = "k8s-cluster"
  description = "Zonal Kubernetes cluster"
  network_id  = yandex_vpc_network.main.id

  master {
    version   = "1.31"
    public_ip = true

    zonal {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }
  }

  service_account_id      = data.yandex_iam_service_account.tf_storage.id
  node_service_account_id = data.yandex_iam_service_account.tf_storage.id
  release_channel         = "REGULAR"
  network_policy_provider = "CALICO"

  depends_on = [yandex_resourcemanager_folder_iam_member.k8s_full_access]
}

