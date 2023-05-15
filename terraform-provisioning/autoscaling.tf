resource "aws_launch_configuration" "my_launch_configuration" {
  image_id        = "ami-03c7d01cf4dedc891"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.my_security_group.id]
  key_name        = "SSH"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum upgrade -y
              yum install docker -y
              usermod -a -G docker ec2-user
              systemctl start docker && systemctl enable docker
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              yum install amazon-efs-utils -y
              systemctl start efs && systemctl enable efs
              mkdir /efs
              cd /
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs
              echo ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 | sudo tee -a /etc/fstab
              cd /efs
              mkdir db_data && mkdir wp_data
              echo '
version: "3"
services:
  wordpress:
    image: wordpress:latest
    ports:
      - 80:80
    restart: always
    environment:
      - WORDPRESS_DB_HOST=${aws_db_instance.my_db_instance.endpoint}
      - WORDPRESS_DB_USER=admin
      - WORDPRESS_DB_PASSWORD=wordpress
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - /efs/wp_data:/var/www/html
  db:
    image: mysql:latest
    volumes:
      - /efs/db_data:/var/lib/mysql
    restart: always
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=admin
      - MYSQL_PASSWORD=wordpress
      - MYSQL_ROOT_PASSWORD=wordpress
      - MYSQL_HOST=${aws_db_instance.my_db_instance.endpoint}
      - MYSQL_PORT=3306
volumes:
  wp_data:
  db_data:' > compose.yaml
              docker-compose up -d 
              EOF

  depends_on = [aws_db_instance.my_db_instance]
}
resource "aws_autoscaling_group" "my_autoscaling_group" {
  launch_configuration = aws_launch_configuration.my_launch_configuration.id
  name                 = "my_autoscaling_group"
  min_size             = 1
  max_size             = 4
  desired_capacity     = 2
  vpc_zone_identifier = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]
  target_group_arns = [aws_lb_target_group.my_target_group.arn]
  depends_on = [
    aws_db_instance.my_db_instance,
    aws_security_group_rule.my_security_group_rule_ssh,
    aws_security_group_rule.my_security_group_rule_http,
    aws_security_group_rule.my_security_group_rule_egress,
    aws_launch_configuration.my_launch_configuration,
    aws_efs_mount_target.efs_mount_target_a,
    aws_efs_mount_target.efs_mount_target_b
  ]
}
