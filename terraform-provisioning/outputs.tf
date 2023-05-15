output "DNS-LOADBALANCER" {
  value = aws_lb.my_load_balancer.dns_name
}
