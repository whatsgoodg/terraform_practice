output "alb_dns_name" {
    value = aws_lb.example.dns_name
    description = "The domain name of the load balancer"
}

# output "public_ip" {
#     description = "Web Server Public IP"
#     value = aws_instance.example.public_ip
# }
