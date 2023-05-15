resource "aws_security_group" "my_security_group" {
  name_prefix = "my-security-group"
  vpc_id      = aws_vpc.my_vpc.id
}

resource "aws_security_group_rule" "my_security_group_rule_ssh" {
  security_group_id = aws_security_group.my_security_group.id
  type              = "ingress"

  description = "Allows SSH access"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "my_security_group_rule_http" {
  security_group_id = aws_security_group.my_security_group.id
  type              = "ingress"

  description = "Allows http traffic"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group_rule" "my_security_group_rule_egress" {
  security_group_id = aws_security_group.my_security_group.id
  type              = "egress"

  description = "Allows all outbound traffic"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "my_security_group_rule_mysql" {
  security_group_id = aws_security_group.my_security_group.id
  type              = "ingress"

  description = "MYSQL/Aurora"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "my_security_group_rule_wordpress" {
  security_group_id = aws_security_group.my_security_group.id
  type              = "ingress"

  description = "Allows all http traffic on port 8080"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "bastion_sg" {
  name_prefix = "bastion"
  vpc_id      = aws_vpc.my_vpc.id


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "bastion_sg_rule_egress" {
  security_group_id = aws_security_group.bastion_sg.id
  type              = "egress"

  description = "Allows all outbound traffic"
  from_port   = 0
  to_port     = 0
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]
}