output "alb_dns_name" {
  value       = aws_lb.AppLB.dns_name
  description = "The domain name of the load balancer"
}

output "server_public_ip"{
  value =aws_instance.app_server.public_ip
  description = "The public IP of webserver"
}