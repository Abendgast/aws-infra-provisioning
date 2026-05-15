
# Requirement: Lab 3 & Lab 7 (Storage Architecture) - Maps to Azure Blob Storage and Azure Files spec
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "main" {
  bucket = "az104-lab-storage-${random_id.bucket_suffix.hex}"
  object_lock_enabled = true
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    id     = "MoveToCool"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 180
    }
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.core.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.core_rt.id]
}

resource "aws_efs_file_system" "main" {
  creation_token = "az104-efs"
  encrypted      = true
  tags = {
    Name = "az104-share1"
  }
}

resource "aws_efs_mount_target" "core_shared" {
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.shared.id
  security_groups = [aws_security_group.core_sg.id]
}

resource "aws_ebs_volume" "extra_disk" {
  availability_zone = "${var.aws_region}a"
  size              = 32
  type              = "gp3"
  tags = { Name = "az104-disk1" }
}

resource "aws_volume_attachment" "extra_disk_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.extra_disk.id
  instance_id = aws_instance.core_vm.id
}
