resource "yandex_vpc_security_group" "mysql_sg" {
  name        = "mysql-sg"
  network_id  = yandex_vpc_network.main.id
  description = "SG for Managed MySQL"

  # Разрешаем доступ к MySQL между private-подсетями (и из них)
  ingress {
    protocol    = "TCP"
    port        = 3306
    description = "MySQL from private subnets"
    v4_cidr_blocks = [
      yandex_vpc_subnet.private_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_b.v4_cidr_blocks[0],
    ]
  }

  # ICMP по желанию
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
