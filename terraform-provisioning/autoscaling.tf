resource "aws_launch_configuration" "my_launch_configuration" {
  image_id        = "ami-03c7d01cf4dedc891"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.my_security_group.id]
  key_name        = "SSH"
  user_data       = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum upgrade -y
              sudo yum install -y git
              sudo yum -y install docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo systemctl enable docker
              sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              sudo yum install amazon-efs-utils -y
              sudo systemctl start efs && sudo systemctl enable efs
              sudo mkdir /efs
              cd /
              sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs
              sudo echo 'AllowUsers ec2-user'
              sudo echo ${aws_efs_mount_target.efs_mount_target_a.ip_address}:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 | sudo tee -a /etc/fstab
              git clone https://github.com/XuriMechanics/Atividade_AWS_Docker.git
              mv Atividade_AWS_Docker /efs
              cd /efs
              mkdir db_data && mkdir wp_data
              cd Atividade_AWS_Docker
              sudo echo "${aws_db_instance.my_db_instance.endpoint}" > endpoint.txt
              docker-compose up        
              EOF
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
