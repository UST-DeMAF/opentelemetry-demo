<!-- markdownlint-disable-next-line -->
# <img src="https://opentelemetry.io/img/logos/opentelemetry-logo-nav.png" alt="OTel logo" width="45"> OpenTelemetry Demo

## Welcome to the OpenTelemetry Astronomy Shop Demo with DeMAF extension

This repository contains the OpenTelemetry Astronomy Shop, a microservice-based
distributed system intended to illustrate the implementation of OpenTelemetry in
a near real-world environment.

FOR THE ORIGINAL README [CLICK HERE](./README_original.md).

The purpose of this fork is to extend the Astronomy Shop in three ways:

- Add a database to showcase that a persistence layer can also be part of the architecture without causing any problems.
- Create a deployment model to deploy the shop using [Ansible](https://docs.ansible.com/) and [Terraform](https://developer.hashicorp.com/terraform/docs) besides the given [Docker-Compose](https://opentelemetry.io/docs/demo/docker_deployment/) and  [Kubernetes](https://opentelemetry.io/docs/demo/kubernetes_deployment/).
- Add translated EDMM models for [Kubernetes](./edmm/otel-store_k8s_translated.yaml), [Ansible](./edmm/otel-store_ansible_translated.yaml) and [Terraform](./edmm/otel-store_terraform_translated.yaml) to showcase the transformation result of those three DeMAF plugins in [EDMM](https://github.com/UST-EDMM).


### Database Integration
The database integration ensures that also a persistence layer is used in the provided demo-application,
making the architecture more comprehensive.

Therefore, a [MongoDB](http://mongodb.com) is added, which adds the products of the shop into the database as JSON entries.
In the default variant of the astronomy shop, only a plain file is used to provide the products.

Thus, the logic of the `productcatalogservice` is adapted, to initialize and use the additionally provided MongoDB.

The changes of the `productcatalogservice` and the addition of the MongoDB is integrated into all deployment variants in this fork.

### Translation to Ansible

Lorem # TODO

### Translation to Terraform

Lorem # TODO

### EDMM Models

Lorem # TODO