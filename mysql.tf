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
