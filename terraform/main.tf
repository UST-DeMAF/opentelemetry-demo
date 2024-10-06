terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }
}
# Use these variables to set path in volume blocks of flagd, grafana, otelcol and prometheus containers. 
# This is necessary because the abspath function does not work correctly on windows
variable "project_path" {
  type = string
  default = "/"
  description = "Path to the project"
}

variable "seperator" {
  type = string
  default = "\\"
  description = "Path seperator"
}

provider "docker" {
  # Use on linux or mac
  host = "unix:///var/run/docker.sock"
  # Use on windows
  #host = "npipe:////.//pipe//docker_engine"
}


# Network Ressource
resource "docker_network" "open-telemetry-network" {
  name   = "opentelemetry-demo"
  driver = "bridge"
}

# accounting service container
resource "docker_container" "accountingservice" {
  name       = "accounting-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-accountingservice"
  depends_on = [docker_container.otelcol, docker_container.kafka]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "accountingservice"
  memory     = 120
  restart    = "unless-stopped"
  env = [
    "KAFKA_SERVICE_ADDR=kafka:9092",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=Cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=accountingservice"
  ]
}

#ad service container
resource "docker_container" "adservice" {
  name       = "ad-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-adservice"
  depends_on = [docker_container.otelcol, docker_container.flagd]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "adservice"
  memory     = 300
  restart    = "unless-stopped"
  ports {
    internal = 9555
  }
  env = [
    "AD_SERVICE_PORT=9555",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=Cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_LOGS_EXPORTER=otlp",
    "OTEL_SERVICE_NAME=adservice"
  ]
}

#cart service container

resource "docker_container" "cartservice" {
  name       = "cart-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-cartservice"
  depends_on = [docker_container.valkey-cart, docker_container.otelcol, docker_container.flagd]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "cartservice"
  memory     = 160
  restart    = "unless-stopped"
  ports {
    internal = 7070
  }
  env = [
    "CART_SERVICE_PORT=7070",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "VALKEY_ADDR=valkey-cart:6379",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=cartservice",
    "ASPNETCORE_URLS=http://*:7070"
  ]

}

# checkout service container

resource "docker_container" "checkoutservice" {
  name  = "checkout-service"
  image = "ghcr.io/open-telemetry/demo:1.11.1-checkoutservice"
  depends_on = [docker_container.cartservice,
    docker_container.currencyservice,
    docker_container.emailservice,
    docker_container.paymentservice,
    docker_container.productcatalogservice,
    docker_container.shippingservice,
    docker_container.otelcol,
  docker_container.flagd]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "checkoutservice"
  memory  = 20
  restart = "unless-stopped"
  ports {
    internal = 5050
  }
  env = [
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "CHECKOUT_SERVICE_PORT=5050",
    "CART_SERVICE_ADDR=cartservice:7070",
    "CURRENCY_SERVICE_ADDR=currencyservice:7001",
    "EMAIL_SERVICE_ADDR=http://emailservice:6060",
    "PAYMENT_SERVICE_ADDR=paymentservice:50051",
    "PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice:3550",
    "SHIPPING_SERVICE_ADDR=shippingservice:50050",
    "KAFKA_SERVICE_ADDR=kafka:9092",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=Cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=checkoutservice"

  ]

}

# currency service container

resource "docker_container" "currencyservice" {
  name       = "currency-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-currencyservice"
  depends_on = [docker_container.otelcol]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "currencyservice"
  memory     = 20
  restart    = "unless-stopped"
  ports {
    internal = 7001
  }
  env = [
    "CURRENCY_SERVICE_PORT=7001",
    "VERSION=1.11.1",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_RESOURCE_ATTRIBUTES=ervice.namespace=opentelemetry-demo,service.version=1.11.1,service.name=currencyservice"
  ]

}

# email service container

resource "docker_container" "emailservice" {
  name       = "email-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-emailservice"
  depends_on = [docker_container.otelcol]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "emailservice"
  memory     = 100
  restart    = "unless-stopped"
  ports {
    internal = 6060
  }
  env = [
    "APP_ENV=production",
    "EMAIL_SERVICE_PORT=6060",
    "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://otelcol:4318/v1/traces",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=emailservice"
  ]

}

# fraud detection service container

resource "docker_container" "frauddetectionservice" {
  name       = "frauddetection-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-frauddetectionservice"
  depends_on = [docker_container.otelcol, docker_container.kafka]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "frauddetectionservice"
  memory     = 300
  restart    = "unless-stopped"
  env = [
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "KAFKA_SERVICE_ADDR=kafka:9092",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=Cumulative",
    "OTEL_INSTRUMENTATION_KAFKA_EXPERIMENTAL_SPAN_ATTRIBUTES=true",
    "OTEL_INSTRUMENTATION_MESSAGING_EXPERIMENTAL_RECEIVE_TELEMETRY_ENABLED=true",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=frauddetectionservice"
  ]

}

# frontend container

resource "docker_container" "frontend" {
  name  = "frontend"
  image = "ghcr.io/open-telemetry/demo:1.11.1-frontend"
  depends_on = [docker_container.adservice,
    docker_container.cartservice,
    docker_container.checkoutservice,
    docker_container.currencyservice,
    docker_container.productcatalogservice,
    docker_container.quoteservice,
    docker_container.recommendationservice,
    docker_container.shippingservice,
    docker_container.otelcol,
    docker_container.imageprovider,
    docker_container.flagd
  ]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  memory  = 250
  restart = "unless-stopped"
  ports {
    internal = 8080
  }
  env = [
    "PORT=8080",
    "FRONTEND_ADDR=frontend:8080",
    "AD_SERVICE_ADDR=adservice:9555",
    "CART_SERVICE_ADDR=cartservice:7070",
    "CHECKOUT_SERVICE_ADDR=checkoutservice:5050",
    "CURRENCY_SERVICE_ADDR=currencyservice:7001",
    "PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice:3550",
    "RECOMMENDATION_SERVICE_ADDR=recommendationservice:9001",
    "SHIPPING_SERVICE_ADDR=shippingservice:50050",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "ENV_PLATFORM=local",
    "OTEL_SERVICE_NAME=frontend",
    "PUBLIC_OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:8080/otlp-http/v1/traces",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative",
    "WEB_OTEL_SERVICE_NAME=frontend-web",
    "OTEL_COLLECTOR_HOST=otelcol",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013"
  ]
}

# frontend proxy (envoy) container

resource "docker_container" "frontendproxy" {
  name  = "frontend-proxy"
  image = "ghcr.io/open-telemetry/demo:1.11.1-frontendproxy"
  depends_on = [docker_container.frontend,
    docker_container.loadgenerator,
    docker_container.jaeger,
  docker_container.grafana]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "frontendproxy"
  memory  = 50
  restart = "unless-stopped"
  ports {
    internal = 1000
    external = 1000
  }
  ports {
    internal = 8080
    external = 8080
  }
  env = [
    "FRONTEND_PORT=8080",
    "FRONTEND_HOST=frontend",
    "LOCUST_WEB_HOST=loadgenerator",
    "LOCUST_WEB_PORT=8089",
    "GRAFANA_SERVICE_PORT=3000",
    "GRAFANA_SERVICE_HOST=grafana",
    "JAEGER_SERVICE_PORT=16686",
    "JAEGER_SERVICE_HOST=jaeger",
    "OTEL_COLLECTOR_HOST=otelcol",
    "IMAGE_PROVIDER_HOST=imageprovider",
    "IMAGE_PROVIDER_PORT=8081",
    "OTEL_COLLECTOR_PORT_GRPC=4317",
    "OTEL_COLLECTOR_PORT_HTTP=4318",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "ENVOY_PORT=8080",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013"
  ]

}

# image provider container

resource "docker_container" "imageprovider" {
  name       = "image-provider"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-imageprovider"
  depends_on = [docker_container.otelcol]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "imageprovider"
  memory     = 120
  restart    = "unless-stopped"
  ports {
    internal = 8081
  }
  env = [
    "IMAGE_PROVIDER_PORT=8081",
    "OTEL_COLLECTOR_HOST=otelcol",
    "OTEL_COLLECTOR_PORT_GRPC=4317",
    "OTEL_SERVICE_NAME=imageprovider",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1"
  ]

}

# load generator container

resource "docker_container" "loadgenerator" {
  name  = "load-generator"
  image = "ghcr.io/open-telemetry/demo:1.11.1-loadgenerator"
  depends_on = [docker_container.frontend,
  docker_container.flagd]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "loadgenerator"
  memory  = 1000
  restart = "unless-stopped"
  ports {
    internal = 8089
  }
  env = [
    "LOCUST_WEB_PORT=8089",
    "LOCUST_USERS=10",
    "LOCUST_HOST=http://frontend-proxy:8080",
    "LOCUST_HEADLESS=false",
    "LOCUST_AUTOSTART=true",
    "LOCUST_BROWSER_TRAFFIC_ENABLED=true",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=loadgenerator",
    "PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python",
    "LOCUST_WEB_HOST=0.0.0.0",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013"
  ]

}

# payment service container

resource "docker_container" "paymentservice" {
  name  = "payment-service"
  image = "ghcr.io/open-telemetry/demo:1.11.1-paymentservice"
  depends_on = [docker_container.otelcol,
  docker_container.flagd]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "paymentservice"
  memory  = 120
  restart = "unless-stopped"
  ports {
    internal = 50051
  }
  env = [
    "PAYMENT_SERVICE_PORT=50051",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=paymentservice"
  ]

}

# product catalog service container

resource "docker_container" "productcatalogservice" {
  name  = "product-catalog-service"
  image = "ghcr.io/ust-demaf/demo:1.11.1-productcatalogservice"
  depends_on = [docker_container.otelcol,
    docker_container.flagd,
  docker_container.mongodb-catalog]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "productcatalogservice"
  memory  = 20
  restart = "unless-stopped"
  ports {
    internal = 3550
  }
  env = [
    "PRODUCT_CATALOG_SERVICE_PORT=3550",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=productcatalogservice",
    "MONGO_USERNAME=mongo",
    "MONGO_PASSWORD=mongo_product_catalog",
    "MONGO_HOSTNAME=mongo",
    "MONGO_PORT=27017"
  ]
}

# quote service container

resource "docker_container" "quoteservice" {
  name       = "quote-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-quoteservice"
  depends_on = [docker_container.otelcol]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "quoteservice"
  memory     = 40
  restart    = "unless-stopped"
  ports {
    internal = 8090
  }
  env = [
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318",
    "OTEL_PHP_AUTOLOAD_ENABLED=true",
    "QUOTE_SERVICE_PORT=8090",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=quoteservice",
    "OTEL_PHP_INTERNAL_METRICS_ENABLED=true"
  ]

}

# recommendation service container

resource "docker_container" "recommendationservice" {
  name  = "recommendation-service"
  image = "ghcr.io/open-telemetry/demo:1.11.1-recommendationservice"
  depends_on = [docker_container.productcatalogservice,
    docker_container.otelcol,
    docker_container.flagd
  ]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "recommendationservice"
  memory  = 500
  restart = "unless-stopped"
  ports {
    internal = 9001
  }
  env = [
    "RECOMMENDATION_SERVICE_PORT=9001",
    "PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice:3550",
    "FLAGD_HOST=flagd",
    "FLAGD_PORT=8013",
    "OTEL_PYTHON_LOG_CORRELATION=true",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=recommendationservice",
    "PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python"
  ]

}

# shipping service container

resource "docker_container" "shippingservice" {
  name       = "shipping-service"
  image      = "ghcr.io/open-telemetry/demo:1.11.1-shippingservice"
  depends_on = [docker_container.otelcol]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "shippingservice"
  memory     = 20
  restart    = "unless-stopped"
  ports {
    internal = 50050
  }
  env = [
    "SHIPPING_SERVICE_PORT=50050",
    "QUOTE_SERVICE_ADDR=http://quoteservice:8090",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4317",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=shippingservice"
  ]
}

# dependent services

# flagd feature flagging service container

resource "docker_container" "flagd" {
  name   = "flagd"
  image  = "ghcr.io/open-feature/flagd:v0.11.2"
  memory = 50
  env = [
    "FLAGD_OTEL_COLLECTOR_URI=otelcol:4317",
    "FLAGD_METRICS_EXPORTER=otel",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=flagd"
  ]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  command = [
    "start",
    "--uri",
    "file:./etc/flagd/demo.flagd.json"
  ]
  ports {
    internal = 8013
  }
  volumes {
    # linux or mac
    host_path      = abspath("../src/flagd")
    # windows
    #host_path      = "${var.project_path}${var.seperator}src${var.seperator}flagd"
    container_path = "/etc/flagd"
  }

}

# kafka container

resource "docker_container" "kafka" {
  name    = "kafka"
  image   = "ghcr.io/open-telemetry/demo:1.11.1-kafka"
  memory  = 600
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  restart = "unless-stopped"
  ports {
    internal = 9092
  }
  env = [
    "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092",
    "OTEL_EXPORTER_OTLP_ENDPOINT=http://otelcol:4318",
    "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative",
    "OTEL_RESOURCE_ATTRIBUTES=service.namespace=opentelemetry-demo,service.version=1.11.1",
    "OTEL_SERVICE_NAME=kafka",
    "KAFKA_HEAP_OPTS=-Xmx400m -Xms400m"
  ]
  healthcheck {
    test         = ["nc", "-z", "kafka 9092"]
    start_period = "10s"
    interval     = "5s"
    timeout      = "10s"
    retries      = 10

  }
}

# valkey service container (used by cart container)

resource "docker_container" "valkey-cart" {
  name    = "valkey-cart"
  image   = "valkey/valkey:8.0-alpine"
  user    = "valkey"
  memory  = 20
  restart = "unless-stopped"
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  ports {
    internal = 6379
  }
}

# mongodb service container (used by product catalog container)

resource "docker_container" "mongodb-catalog" {
  name    = "mongodb-catalog"
  image   = "mongo:8.0.0-rc9"
  memory  = 256
  restart = "unless-stopped"
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "mongo"
  ports {
    internal = 27017
    external = 27017
  }
  env = [
    "MONGO_INITDB_ROOT_USERNAME=mongo",
    "MONGO_INITDB_ROOT_PASSWORD=mongo_product_catalog"
  ]
  healthcheck {
    test         = [ "echo", "db.runCommand(\"ping\").ok", "|", "mongosh", "localhost:27017/test", "--quiet"]
    start_period = "10s"
    interval     = "5s"
    timeout      = "10s"
    retries      = 10

  }

}

# telemetry components

# jaeger container

resource "docker_container" "jaeger" {
  name  = "jaeger"
  image = "jaegertracing/all-in-one:1.60"
  command = [
    "--memory.max-traces=5000",
    "--query.base-path=/jaeger/ui",
    "--prometheus.server-url=http://prometheus:9090",
    "--prometheus.query.normalize-calls=true",
    "--prometheus.query.normalize-duration=true"
  ]
  memory  = 400
  restart = "unless-stopped"
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  ports {
    internal = 16686
  }
  ports {
    internal = 4317
  }
  env = [
    "METRICS_STORAGE_TYPE=prometheus"
  ]
}

# grafana container

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = "grafana/grafana:11.2.0"
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  memory  = 100
  restart = "unless-stopped"
  env     = ["GF_INSTALL_PLUGINS=grafana-opensearch-datasource"]
  volumes {
    # linux or mac
    host_path      = abspath("../src/grafana/grafana.ini")
    # windows
    #host_path      = "${var.project_path}${var.seperator}src${var.seperator}grafana${var.seperator}grafana.ini"
    container_path = "/etc/grafana/grafana.ini"

  }
  volumes {
    # linux or mac
    host_path      = abspath("../src/grafana/provisioning/")
    # windows	
    #host_path      = "${var.project_path}${var.seperator}src${var.seperator}grafana${var.seperator}provisioning{var.seperator}"
    container_path = "/etc/grafana/provisioning/"
  }
  ports {
    internal = 3000
  }

}

# opentelemetry collector container

resource "docker_container" "otelcol" {
  name       = "otel-col"
  image      = "otel/opentelemetry-collector-contrib:0.108.0"
  depends_on = [docker_container.jaeger]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  hostname = "otelcol"
  memory     = 200
  restart    = "unless-stopped"
  command    = ["--config=/etc/otelcol-config.yml", "--config=/etc/otelcol-config-extras.yml"
  ]
  user = "0:0"
  volumes {
    # linux or mac
    host_path      = abspath("../src/otelcollector/otelcol-config.yml")
    # windows
    #host_path      = "${var.project_path}${var.seperator}src${var.seperator}otelcollector${var.seperator}otelcol-config.yml"
    container_path = "/etc/otelcol-config.yml"
  }
  volumes {
    # linux or mac
    host_path      = abspath("../src/otelcollector/otelcol-config-extras.yml")
    # windows
    # host_path      = "${var.project_path}${var.seperator}src${var.seperator}otelcollector${var.seperator}otelcol-config-extras.yml"
    container_path = "/etc/otelcol-config-extras.yml"
  }
  volumes {
    host_path = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  ports {
    internal = 4317
  }
  ports {
    internal = 4318
  }
  env = ["ENVOY_PORT=8080",
          "OTEL_COLLECTOR_HOST=otelcol",
          "OTEL_COLLECTOR_PORT_GRPC=4317",
          "OTEL_COLLECTOR_PORT_HTTP=4318"
          ]

}

# prometheus container

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = "quay.io/prometheus/prometheus:v2.54.1"
  command = ["--web.console.templates=/etc/prometheus/consoles", 
    "--web.console.libraries=/etc/prometheus/console_libraries", 
    "--storage.tsdb.retention.time=1h",
    "--config.file=/etc/prometheus/prometheus-config.yaml", 
    "--storage.tsdb.path=/prometheus", 
    "--web.enable-lifecycle", 
    "--web.route-prefix=/", 
    "--enable-feature=exemplar-storage", 
    "--enable-feature=otlp-write-receiver"
  ]
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  volumes {
    # linux or mac
    host_path      = abspath("../src/prometheus/prometheus-config.yaml")
    # windows
    #host_path      = "${var.project_path}${var.seperator}src${var.seperator}prometheus${var.seperator}prometheus-config.yaml"
    container_path = "/etc/prometheus/prometheus-config.yaml"
  }
  memory  = 300
  restart = "unless-stopped"
  ports {
    internal = 9090
    external = 9090
  }
}

# open search container

resource "docker_container" "opensearch" {
  name    = "opensearch"
  image   = "opensearchproject/opensearch:2.16.0"
  network_mode = "bridge"
  networks_advanced {
    name = docker_network.open-telemetry-network.name
  }
  memory  = 1000
  restart = "unless-stopped"
  env = [
    "cluster.name=demo-cluster",
    "node.name=demo-node",
    "bootstrap.memory_lock=true",
    "discovery.type=single-node",
    "OPENSEARCH_JAVA_OPTS=-Xms300m -Xmx300m",
    "DISABLE_INSTALL_DEMO_CONFIG=true",
    "DISABLE_SECURITY_PLUGIN=true"
  ]
  ports {
    internal = 9200
  }
}
