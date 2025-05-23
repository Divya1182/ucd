resource "aws_s3_access_point" "s3_access_point" {
  bucket = local.bef_s3_bucket_name
  name   = "${local.bef_s3_bucket_name}-ap"

  public_access_block_configuration {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3control_access_point_policy" "s3_access_point_policy" {
  access_point_arn = aws_s3_access_point.s3_access_point.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:GetObject*"
        Principal = {
          AWS = var.ap_polaris
        }
        Resource = "${aws_s3_access_point.s3_access_point.arn}/object/*"
      },
      {
        Effect = "Allow"
        Action = "s3:ListBucket"
        Principal = {
          AWS = var.ap_polaris
        }
        Resource = "${aws_s3_access_point.s3_access_point.arn}"
      }
    ]
  })
}


