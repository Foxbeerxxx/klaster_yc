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

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота 2](ссылка на скриншот 2)`


---

### Задание 3

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`

### Задание 4

`Приведите ответ в свободной форме........`

1. `Заполните здесь этапы выполнения, если требуется ....`
2. `Заполните здесь этапы выполнения, если требуется ....`
3. `Заполните здесь этапы выполнения, если требуется ....`
4. `Заполните здесь этапы выполнения, если требуется ....`
5. `Заполните здесь этапы выполнения, если требуется ....`
6. 

```
Поле для вставки кода...
....
....
....
....
```

`При необходимости прикрепитe сюда скриншоты
![Название скриншота](ссылка на скриншот)`
