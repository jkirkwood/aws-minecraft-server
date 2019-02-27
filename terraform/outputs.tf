output "server_ip" {
  description = "Minecraft server public IP address"
  value       = "${aws_instance.server.public_ip}"
}

output "launcher_base_url" {
  description = "Base URL of server launch api"
  value       = "${aws_api_gateway_deployment.launcher.invoke_url}"
}
