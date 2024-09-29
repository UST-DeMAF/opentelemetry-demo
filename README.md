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

To verify the [Ansible MPS Plugin](https://github.com/UST-DeMAF/ansible-mps-plugin) the Astronomy Shop is available as Ansible installation.
It is based on the [Docker-Compose](https://opentelemetry.io/docs/demo/docker_deployment/) and installs all components of the shop as docker containers on the local Docker runtime.
For each component there is a dedicated Ansible Role representing the loose coupling of the components.

A usage guide can be found in the dedicated [README in /ansible](./ansible/README.md).

### Translation to Terraform

To verify the [Terraform MPS Plugin](https://github.com/UST-DeMAF/terraform-mps-plugin) the Astronomy Shop is available as Terraform installation.
It is based on the [Docker-Compose](https://opentelemetry.io/docs/demo/docker_deployment/) and installs all components of the shop as docker containers on the local Docker runtime.

A usage guide can be found in the dedicated [README in /terraform](./terraform/README.md).

### EDMM Models

For all three evaluated technologies (Ansible, Terraform, Kubernetes) there is a transformed target model available. 

The target EDMM models can be found in the [/edmm directory](./edmm)

In each model the goal is to retrieve a component for each deployed Astronomy Shop component 
and as many _connects-to_ and _hosted_on_ relations as possible.

This in common, there are also differences in the target models.

Due to the imperative character of Ansible, in the [Ansible target model](./edmm/otel-store_ansible_translated.yaml), each component has operations representing the installation of the Docker containers.

In the [Terraform target model](./edmm/otel-store_terraform_translated.yaml), there are common component types for all _docker_containers_, 
as they all use the same terraform ressource type. This is different in the other two evaluated technologies, where each component has a dedicated type.

For the Kubernetes model there are two variants. The [first](./edmm/otel-store_k8s_translated.yaml) is the actual result of the translation, lacking _hosted_on_ relations.
That is, as the Kubernetes plugin only creates _hosted_on_ relations when a component named _container_runtime_ with a matching type is present in the TADM.
Therefore, there is a [second target model](./edmm/otel-store_k8s_translated_with_container_runtime.yaml) where this _container_runtime_ has been manually added, before creating the relations.
Thus, all components obtain a _hosted_on_ relation.