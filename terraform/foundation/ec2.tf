data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# One security group for both servers: SSH, Jenkins and SonarQube UI from my IP only,
# and all traffic between the two servers.
resource "aws_security_group" "tools" {
  name        = "devsecops-tools-sg"
  description = "Jenkins and SonarQube servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH, Jenkins, SonarQube from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Jenkins UI from my IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "SonarQube UI from my IP"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Server to server"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance role so Jenkins can push to ECR without stored AWS keys
resource "aws_iam_role" "tools" {
  name = "devsecops-tools-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.tools.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "tools" {
  name = "devsecops-tools-profile"
  role = aws_iam_role.tools.name
}

resource "aws_instance" "server" {
  for_each = toset(["jenkins", "sonarqube"])

  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "m7i-flex.large"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.tools.id]
  iam_instance_profile   = aws_iam_instance_profile.tools.name
  key_name               = var.key_name

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  tags = { Name = "devsecops-${each.key}" }

  lifecycle {
    ignore_changes = [ami]
  }
}
