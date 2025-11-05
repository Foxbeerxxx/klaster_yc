# Домашнее задание к занятию "`Кластеры. Ресурсы под управлением облачных провайдеров`" - `Татаринцев Алексей`



---

### Задание 1


1. `Для выполнения задания, беру предыдущие задания и правлю`

2. `network.tf`

```
resource "yandex_vpc_network" "main" {
  name = "netology-vpc"
}

# Две private-подсети под MySQL в разных зонах
resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.10.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.20.0/24"]
}


```

3. `sg.tf`

```
resource "yandex_vpc_security_group" "mysql_sg" {
  name        = "mysql-sg"
  network_id  = yandex_vpc_network.main.id
  description = "SG for Managed MySQL"

  # Разрешаем доступ к MySQL между private-подсетями (и из них)
  ingress {
    protocol       = "TCP"
    port           = 3306
    description    = "MySQL from private subnets"
    v4_cidr_blocks = [
      yandex_vpc_subnet.private_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_b.v4_cidr_blocks[0],
    ]
  }

 
  ingress {
    protocol       = "ICMP"
    description    = "Ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

```


4. `mysql.tf`

```
variable "db_user" {
  type    = string
  default = "netology_user"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "StrongPass123!" 
}

resource "yandex_mdb_mysql_cluster" "mysql" {
  name        = "netology-mysql"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.main.id
  version     = "8.0"
  deletion_protection = true

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  maintenance_window { type = "ANYTIME" } # произвольное окно

  security_group_ids = [yandex_vpc_security_group.mysql_sg.id]

  resources {
    resource_preset_id = "b2.medium"   # Broadwell, 50% CPU
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  # Размещение хостов кластера по зонам и private-подсетям
  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.private_a.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.private_b.id
    assign_public_ip = false
  }
}

resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = "netology_db"
}

resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = var.db_user
  password   = var.db_password

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = ["ALL"]
  }
}

```
5. `outputs.tf`

```
output "mysql_hosts" {
  value = [for h in yandex_mdb_mysql_cluster.mysql.host : h.fqdn]
}

output "mysql_connection" {
  value = {
    database = yandex_mdb_mysql_database.db.name
    user     = var.db_user
  }
  sensitive = true
}

```

6. `Ну и запуск`

```
terraform fmt
terraform validate
terraform init -upgrade
terraform apply

```
![1](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img1.png)

![2](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img2.png)

![3](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img3.png)

---

### Задание 2


1. `k8s_nodes.tf`

```
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

```

2. `k8s_outputs.tf`
```
output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s.id
}

output "k8s_master_external_ipv4" {
  value = yandex_kubernetes_cluster.k8s.master[0].external_v4_address
}

```
3. `k8s-sa.tf`

```
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

```
4. `k8s.tf`

```
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


```

5. `kms.tf`

```
resource "yandex_kms_symmetric_key" "k8s_key" {
  name                = "kms-bucket-key"
  description         = "Key for Kubernetes encryption"
  default_algorithm   = "AES_256"
  rotation_period     = "8760h" # 1 год
  deletion_protection = false
}

```

6. `mysql.tf`

```
variable "db_user" {
  type    = string
  default = "netology_user"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "StrongPass123!"
}

resource "yandex_mdb_mysql_cluster" "mysql" {
  name                = "netology-mysql"
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.main.id
  version             = "8.0"
  deletion_protection = true

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  maintenance_window { type = "ANYTIME" }

  security_group_ids = [yandex_vpc_security_group.mysql_sg.id]

  resources {
    resource_preset_id = "b2.medium"
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.private_a.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.private_b.id
    assign_public_ip = false
  }
}

resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = "netology_db"
}

resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = var.db_user
  password   = var.db_password

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = ["ALL"]
  }
}


```
7. `network.tf`

```
resource "yandex_vpc_network" "main" {
  name = "netology-network"
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.10.0/24"]
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.20.20.0/24"]
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}


```

8. `outputs.tf`

```
output "mysql_hosts" {
  value = [for h in yandex_mdb_mysql_cluster.mysql.host : h.fqdn]
}

output "mysql_connection" {
  value = {
    database = yandex_mdb_mysql_database.db.name
    user     = var.db_user
  }
  sensitive = true
}


```
9. `provider.tf`

```
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.98"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = "b1gvjpk4qbrvling8qq1"
  folder_id                = "b1gse67sen06i8u6ri78"
  zone                     = "ru-central1-a"
}

```
10. `sg.tf`

```
resource "yandex_vpc_security_group" "mysql_sg" {
  name        = "mysql-sg"
  description = "SG for Managed MySQL"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol    = "TCP"
    port        = 3306
    description = "MySQL from private subnets"
    v4_cidr_blocks = [
      yandex_vpc_subnet.private_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_b.v4_cidr_blocks[0],
    ]
  }

  ingress {
    protocol       = "ICMP"
    description    = "Ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

```

11. `Проверяю`

```
terraform fmt
terraform validate
terraform apply

```
![4](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img4.png)

![5](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img5.png)


12. `Устанавливаю kubeconfig для kubectl`
```
yc managed-kubernetes cluster get-credentials k8s-cluster --external --force

```
13. `Проверяю подключение`

```
kubectl get nodes
```
14. `Проверяю доступ к API`

```
kubectl cluster-info
```
![6](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img6.png)


15. `Создаю секрет для подключения к БД`

```
kubectl create secret generic mysql-secret \
  --from-literal=dbhost=rcla-f3i9pfdlnkk5lhsg.mdb.yandexcloud.net \
  --from-literal=dbuser=netology_user \
  --from-literal=dbpass=StrongPass123!
```


16. `Создаю Deployment и Service`

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: phpmyadmin
  template:
    metadata:
      labels:
        app: phpmyadmin
    spec:
      containers:
      - name: phpmyadmin
        image: phpmyadmin/phpmyadmin:latest
        ports:
        - containerPort: 80
        env:
        - name: PMA_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: dbhost
        - name: PMA_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: dbuser
        - name: PMA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: dbpass
---
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: phpmyadmin

```

17. `Применяю манифест:`

```
kubectl apply -f phpmyadmin.yaml
```
18. `Проверяю получение внешнего IP`

```
kubectl get svc phpmyadmin

```
![7](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img7.png)


19. `Пробую подключаться, но БД ругается...на этом уже и сломал зубы`

![8](https://github.com/Foxbeerxxx/klaster_yc/blob/main/img/img8.png)

