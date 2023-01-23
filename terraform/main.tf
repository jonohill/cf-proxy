terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

resource "null_resource" "node_modules" {
  triggers = {
    package_json = filemd5("${path.module}/../package.json")
  }

  provisioner "local-exec" {
    command     = "npm install"
    working_dir = "${path.module}/.."
  }
}

resource "null_resource" "build" {
  triggers = {
    source_files = md5(join("", [for f in fileset("${path.module}/../src", "*") : filemd5("${path.module}/../src/${f}")]))
  }

  provisioner "local-exec" {
    command     = "npm run build"
    working_dir = "${path.module}/.."
  }

  depends_on = [null_resource.node_modules]
}

data "cloudflare_zones" "this" {
  filter {
    name   = var.zone_name
    status = "active"
  }
}

data "cloudflare_zone" "this" {
  zone_id = data.cloudflare_zones.this.zones[0].id
}

resource "cloudflare_record" "this" {
  zone_id = data.cloudflare_zone.this.id
  name    = var.subdomain
  value   = "100::"
  type    = "AAAA"
  proxied = true
}

resource "cloudflare_worker_script" "this" {
  account_id = data.cloudflare_zone.this.account_id

  name    = var.name
  content = file("${path.module}/../dist/index.js")
  module  = true

  plain_text_binding {
    name = "UPSTREAM_URL"
    text = var.upstream_url
  }

  depends_on = [null_resource.build]
}

resource "cloudflare_worker_route" "this" {
  zone_id     = data.cloudflare_zone.this.id
  pattern     = "${var.subdomain}.${data.cloudflare_zone.this.name}/*"
  script_name = cloudflare_worker_script.this.name

  depends_on = [cloudflare_record.this]
}
