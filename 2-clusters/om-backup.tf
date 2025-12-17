# Enable backup daemon in Ops Manager
resource "null_resource" "enable_backup_daemon" {
  count = local.om_config.backup_type != "none" ? 1 : 0
  provisioner "local-exec" {
    environment = {
      OM_URL      = local.om_access_url
      HEADDB      = "/data/head/" # Must ends with /
      PUBLIC_KEY  = local.om_public_key
      PRIVATE_KEY = local.om_private_key
    }
    command = "python3 ${path.root}/../scripts/enable_daemon.py"
  }
}

resource "null_resource" "enable_mongo_oplog_store" {
  count = (local.om_config.backup_type == "mongo" || local.om_config.backup_type == "fileSystem") ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      OM_URL      = local.om_access_url
      PUBLIC_KEY  = local.om_public_key
      PRIVATE_KEY = local.om_private_key
      HOSTS_STR   = join(",", local.backup_hosts)
      OPLOG_USER  = local.backing_db_credentials.name
      OPLOG_PWD   = local.backing_db_credentials.pwd
      STORE_ID    = "MongoOplogStore1"
      STORE_TYPE  = "oplog"
      BACKUP_TYPE = "mongo"
    }
    command = "python3 ${path.root}/../scripts/configure_backup.py"
  }
  depends_on = [null_resource.create_backup_rs]
}

resource "null_resource" "enable_mongo_snapshot_store" {
  count = local.om_config.backup_type == "mongo" ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      OM_URL      = local.om_access_url
      PUBLIC_KEY  = local.om_public_key
      PRIVATE_KEY = local.om_private_key
      HOSTS_STR   = join(",", local.backup_hosts)
      OPLOG_USER  = local.backing_db_credentials.name
      OPLOG_PWD   = local.backing_db_credentials.pwd
      STORE_ID    = "MongoSnapshotStore1"
      STORE_TYPE  = "snapshot"
      BACKUP_TYPE = "mongo"
    }
    command = "python3 ${path.root}/../scripts/configure_backup.py"
  }
  depends_on = [null_resource.create_backup_rs]
}

# Create S3 buckets for backup stores
module "oplog_store" {
  count       = local.om_config.backup_type == "s3" ? 1 : 0
  source      = "../modules/s3"
  bucket_name = local.oplog_store_bucket
  tags        = local.tags
}
module "snapshot_store" {
  count       = local.om_config.backup_type == "s3" ? 1 : 0
  source      = "../modules/s3"
  bucket_name = local.snapshot_store_bucket
  tags        = local.tags
}

resource "null_resource" "enable_s3_oplog_store" {
  count = local.om_config.backup_type == "s3" ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      OM_URL             = local.om_access_url
      PUBLIC_KEY         = local.om_public_key
      PRIVATE_KEY        = local.om_private_key
      HOSTS_STR          = join(",", local.backup_hosts)
      OPLOG_USER         = local.backing_db_credentials.name
      OPLOG_PWD          = local.backing_db_credentials.pwd
      STORE_ID           = "S3OplogStore1"
      STORE_TYPE         = "oplog"
      BACKUP_TYPE        = "s3"
      S3_BUCKET_NAME     = "${local.s3_config.prefix}-oplog-store"
      S3_BUCKET_ENDPOINT = "${local.s3_config.endpoint}"
    }
    command = "python3 ${path.root}/../scripts/configure_backup.py"
  }
  depends_on = [null_resource.create_backup_rs, module.oplog_store]
}

resource "null_resource" "enable_s3_snapshot_store" {
  count = local.om_config.backup_type == "s3" ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      OM_URL             = local.om_access_url
      PUBLIC_KEY         = local.om_public_key
      PRIVATE_KEY        = local.om_private_key
      HOSTS_STR          = join(",", local.backup_hosts)
      OPLOG_USER         = local.backing_db_credentials.name
      OPLOG_PWD          = local.backing_db_credentials.pwd
      STORE_ID           = "S3SnapshotStore1"
      STORE_TYPE         = "snapshot"
      BACKUP_TYPE        = "s3"
      S3_BUCKET_NAME     = "${local.s3_config.prefix}-snapshot-store"
      S3_BUCKET_ENDPOINT = "${local.s3_config.endpoint}"
    }
    command = "python3 ${path.root}/../scripts/configure_backup.py"
  }
  depends_on = [null_resource.create_backup_rs, module.snapshot_store]
}

resource "null_resource" "enable_fs_snapshot_store" {
  count = local.om_config.backup_type == "fileSystem" ? 1 : 0
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    environment = {
      OM_URL          = local.om_access_url
      PUBLIC_KEY      = local.om_public_key
      PRIVATE_KEY     = local.om_private_key
      STORE_ID        = "FSSnapshotStore1"
      STORE_TYPE      = "snapshot"
      BACKUP_TYPE     = "fileSystem"
      FILESYSTEM_PATH = "/data/snapshots"
    }
    command = "python3 ${path.root}/../scripts/configure_backup.py"
  }
  depends_on = [null_resource.create_backup_rs]
}
