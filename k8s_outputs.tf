output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s.id
}

output "k8s_master_external_ipv4" {
  value = yandex_kubernetes_cluster.k8s.master[0].external_v4_address
}

