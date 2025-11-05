data "yandex_iam_service_account" "tf_storage" {
  name = "tf-storage"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_full_access" {
  for_each = toset([
    "editor",
    "vpc.admin",
    "load-balancer.admin",
    "container-registry.admin",
    "kms.admin",
    "compute.admin"
  ])

  folder_id = "b1gse67sen06i8u6ri78"
  role      = each.key
  member    = "serviceAccount:${data.yandex_iam_service_account.tf_storage.id}"
}
