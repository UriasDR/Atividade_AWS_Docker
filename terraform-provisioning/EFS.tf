resource "aws_security_group" "efs_security_group" {
  name_prefix = "efs-security-group"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "efs" {
  depends_on = [aws_vpc.my_vpc, aws_security_group.efs_security_group]

  creation_token = "my-efs"

  tags = {
    Name = "my-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_a" {
  depends_on = [aws_subnet.subnet_a, aws_efs_file_system.efs, aws_security_group.efs_security_group]

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.subnet_a.id

  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_mount_target" "efs_mount_target_b" {
  depends_on = [aws_subnet.subnet_b, aws_efs_file_system.efs, aws_security_group.efs_security_group]

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.subnet_b.id

  security_groups = [aws_security_group.efs_security_group.id]
}
