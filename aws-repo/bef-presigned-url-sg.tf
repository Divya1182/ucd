resource "aws_security_group" "presigned-url-sg" {
  name        = var.vpc_security_group_name
  description = "Allow TCP Traffics to and from port 443"
  vpc_id      = module.presigned-url-vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["10.0.0.0/8"]
    prefix_list_ids = [
      module.presigned-url-vpc.vpc_endpoints_gateway[0].s3.prefix_list_id,
      data.aws_vpc_endpoint.dynamo-gateway-endpoint.prefix_list_id
    ]
  }

  tags = merge(
    var.required_common_tags,
    var.extra_tags,
    {
      Name = var.vpc_security_group_name
    }
  )
}
