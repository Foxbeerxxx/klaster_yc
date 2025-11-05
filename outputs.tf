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
