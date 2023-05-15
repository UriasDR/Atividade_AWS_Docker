resource "aws_db_subnet_group" "my_db_subnet_group" {
  name        = "my-db-subnet-group"
  description = "My DB subnet group"

  subnet_ids = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]
}

resource "aws_db_instance" "my_db_instance" {
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  identifier             = "my-db-instance"
  username               = "admin"
  password               = "wordpress"
  name                   = "wordpress"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name

  tags = {
    Name = "my-db-instance"
  }
}