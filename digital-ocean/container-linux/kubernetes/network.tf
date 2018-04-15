resource "digitalocean_firewall" "rules" {
  name = "${var.cluster_name}"

  tags = ["${var.cluster_name}-controller", "${var.cluster_name}-worker"]

  # allow ssh, http/https ingress, and peer-to-peer traffic
  inbound_rule = [
    {
      protocol         = "tcp"
      port_range       = "${var.ssh_port}"
      source_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol         = "udp"
      port_range       = "1-65535"
      source_tags      = ["${digitalocean_tag.controllers.name}", "${digitalocean_tag.workers.name}"]
      source_addresses = ["${digitalocean_loadbalancer.public-loadbalancer.ip}"]
    },
    {
      protocol         = "tcp"
      port_range       = "1-65535"
      source_tags      = ["${digitalocean_tag.controllers.name}", "${digitalocean_tag.workers.name}"]
      source_addresses = ["${digitalocean_loadbalancer.public-loadbalancer.ip}"]
    },
  ]

  # allow all outbound traffic
  outbound_rule = [
    {
      protocol              = "tcp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "udp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
    {
      protocol              = "icmp"
      port_range            = "1-65535"
      destination_addresses = ["0.0.0.0/0", "::/0"]
    },
  ]

  depends_on = ["digitalocean_loadbalancer.public-loadbalancer"]
}

resource "digitalocean_loadbalancer" "public-loadbalancer" {
  name   = "${var.cluster_name}-loadbalancer"
  region = "${var.region}"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 443
    target_protocol = "https"

    tls_passthrough = true
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = ["${digitalocean_droplet.workers.*.id}"]
}
