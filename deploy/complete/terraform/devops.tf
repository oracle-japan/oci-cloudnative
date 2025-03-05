data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid
}

data "oci_objectstorage_namespace" "namespace" {
}

locals {
  home_region_key = lower(data.oci_identity_tenancy.tenant_details.home_region_key)
}

resource "oci_artifacts_container_repository" "mushop_orders_registry" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop-orders"
  is_public      = true
}

resource "oci_artifacts_container_repository" "mushop_api_registry" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop-api"
  is_public      = true
}

resource "oci_artifacts_container_repository" "mushop_fulfillment_registry" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop-fulfillment"
  is_public      = true
}

resource "oci_artifacts_container_repository" "mushop_storefront_registry" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop-storefront"
  is_public      = true
}

resource "oci_artifacts_container_repository" "mushop_setup_registry" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop/mushop-setup"
  is_public      = true
}

resource "oci_artifacts_container_repository" "mushop_registry" {
  compartment_id = var.compartment_ocid
  display_name   = "mushop/mushop"
  is_public      = true
}

resource "oci_artifacts_repository" "mushop_helm_artifact" {
  compartment_id  = var.compartment_ocid
  is_immutable    = false
  repository_type = "GENERIC"
  display_name    = "mushop-helm-artifact"
}

resource "oci_devops_project" "mushop_devops_project" {
  compartment_id = var.compartment_ocid
  name           = "mushop"
  notification_config {
    topic_id = oci_ons_notification_topic.mushop_topic.topic_id
  }
}

resource "oci_devops_repository" "mushop_repository" {
  project_id      = oci_devops_project.mushop_devops_project.id
  name            = "mushop-devops"
  repository_type = "HOSTED"
}

resource "oci_devops_deploy_artifact" "mushop_orders_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-orders"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "DOCKER_IMAGE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri = format(
      "%s.ocir.io/%s/mushop-orders:$${VERSION}",
      local.home_region_key,
      local.namespace
    )
  }
}

resource "oci_devops_deploy_artifact" "mushop_api_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-api"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "DOCKER_IMAGE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri = format(
      "%s.ocir.io/%s/mushop-api:$${VERSION}",
      local.home_region_key,
      local.namespace
    )
  }
}

resource "oci_devops_deploy_artifact" "mushop_fulfillment_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-fulfillment"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "DOCKER_IMAGE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri = format(
      "%s.ocir.io/%s/mushop-fulfillment:$${VERSION}",
      local.home_region_key,
      local.namespace
    )
  }
}

resource "oci_devops_deploy_artifact" "mushop_storefront_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-storefront"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "DOCKER_IMAGE"
  deploy_artifact_source {
    deploy_artifact_source_type = "OCIR"
    image_uri = format(
      "%s.ocir.io/%s/mushop-storefront:$${VERSION}",
      local.home_region_key,
      local.namespace
    )
  }
}

resource "oci_devops_deploy_artifact" "mushop_setup_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-setup"
  argument_substitution_mode = "NONE"
  deploy_artifact_type       = "HELM_CHART"
  deploy_artifact_source {
    deploy_artifact_source_type = "HELM_CHART"
    deploy_artifact_version     = "$${VERSION}"
    chart_url = format(
      "oci://%s.ocir.io/%s/mushop/mushop-setup",
      local.home_region_key,
      local.namespace
    )
  }
}

resource "oci_devops_deploy_artifact" "mushop_deploy_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop"
  argument_substitution_mode = "NONE"
  deploy_artifact_type       = "HELM_CHART"
  deploy_artifact_source {
    deploy_artifact_source_type = "HELM_CHART"
    deploy_artifact_version     = "$${VERSION}"
    chart_url = format(
      "oci://%s.ocir.io/%s/mushop/mushop",
      local.home_region_key,
      local.namespace
    )
  }
}

resource "oci_devops_deploy_artifact" "mushop_values_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "values"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    deploy_artifact_version     = "$${VERSION}"
    deploy_artifact_path        = "values"
    repository_id               = oci_artifacts_repository.mushop_helm_artifact.id
  }
}

resource "oci_devops_deploy_artifact" "mushop_storefront_values_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-storefront-values"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    deploy_artifact_version     = "$${VERSION}"
    deploy_artifact_path        = "mushop-storefront"
    repository_id               = oci_artifacts_repository.mushop_helm_artifact.id
  }
}

resource "oci_devops_deploy_artifact" "mushop_orders_values_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-orders-values"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    deploy_artifact_version     = "$${VERSION}"
    deploy_artifact_path        = "mushop-orders"
    repository_id               = oci_artifacts_repository.mushop_helm_artifact.id
  }
}

resource "oci_devops_deploy_artifact" "mushop_fulfillment_values_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-fulfillment-values"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    deploy_artifact_version     = "$${VERSION}"
    deploy_artifact_path        = "mushop-fulfillment"
    repository_id               = oci_artifacts_repository.mushop_helm_artifact.id
  }
}

resource "oci_devops_deploy_artifact" "mushop_api_values_artifact" {
  project_id                 = oci_devops_project.mushop_devops_project.id
  display_name               = "mushop-api-values"
  argument_substitution_mode = "SUBSTITUTE_PLACEHOLDERS"
  deploy_artifact_type       = "GENERIC_FILE"
  deploy_artifact_source {
    deploy_artifact_source_type = "GENERIC_ARTIFACT"
    deploy_artifact_version     = "$${VERSION}"
    deploy_artifact_path        = "mushop-api"
    repository_id               = oci_artifacts_repository.mushop_helm_artifact.id
  }
}

resource "oci_devops_trigger" "mushop_trigger" {
  project_id     = oci_devops_project.mushop_devops_project.id
  display_name   = "deploy-trigger"
  repository_id  = oci_devops_repository.mushop_repository.id
  trigger_source = "DEVOPS_CODE_REPOSITORY"
  actions {
    build_pipeline_id = oci_devops_build_pipeline.mushop_build_pipeline.id
    type              = "TRIGGER_BUILD_PIPELINE"
    filter {
      events         = ["PUSH"]
      trigger_source = "DEVOPS_CODE_REPOSITORY"
    }
  }
}

resource "oci_devops_build_pipeline" "mushop_build_pipeline" {
  project_id   = oci_devops_project.mushop_devops_project.id
  display_name = "mushop-build"
  build_pipeline_parameters {
    items {
      name          = "REGION"
      description   = "Region key of mushop environment."
      default_value = local.home_region_key
    }
    items {
      name          = "NAMESPACE"
      description   = "Namespace of Object Storage."
      default_value = local.namespace
    }
  }
}

resource "oci_devops_build_pipeline_stage" "mushop_helm" {
  display_name              = "helm"
  build_pipeline_id         = oci_devops_build_pipeline.mushop_build_pipeline.id
  build_pipeline_stage_type = "BUILD"
  image                     = "OL7_X86_64_STANDARD_10"
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.mushop_build_pipeline.id
    }
  }
  build_spec_file = "build_spec.yaml"
  build_source_collection {
    items {
      branch          = "main"
      connection_type = "DEVOPS_CODE_REPOSITORY"
      name            = "main"
      repository_id   = oci_devops_repository.mushop_repository.id
      repository_url  = oci_devops_repository.mushop_repository.http_url
    }
  }
}

resource "oci_devops_build_pipeline_stage" "mushop_stack_ship" {
  display_name              = "mushop-stack-ship"
  build_pipeline_id         = oci_devops_build_pipeline.mushop_build_pipeline.id
  build_pipeline_stage_type = "DELIVER_ARTIFACT"
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.mushop_helm.id
    }
  }
  deliver_artifact_collection {
    items {
      artifact_name = "mushop-orders"
      artifact_id   = oci_devops_deploy_artifact.mushop_orders_artifact.id
    }
    items {
      artifact_name = "mushop-fulfillment"
      artifact_id   = oci_devops_deploy_artifact.mushop_fulfillment_artifact.id
    }
    items {
      artifact_name = "mushop-api"
      artifact_id   = oci_devops_deploy_artifact.mushop_api_artifact.id
    }
    items {
      artifact_name = "mushop-storefront"
      artifact_id   = oci_devops_deploy_artifact.mushop_storefront_artifact.id
    }
    items {
      artifact_name = "values"
      artifact_id   = oci_devops_deploy_artifact.mushop_values_artifact.id
    }
  }
}

resource "oci_devops_build_pipeline_stage" "mushop_trigger_deployment_pipeline" {
  display_name              = "deploy-call"
  build_pipeline_id         = oci_devops_build_pipeline.mushop_build_pipeline.id
  build_pipeline_stage_type = "TRIGGER_DEPLOYMENT_PIPELINE"
  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline_stage.mushop_stack_ship.id
    }
  }
  deploy_pipeline_id             = oci_devops_deploy_pipeline.mushop_deploy_pipeline.id
  is_pass_all_parameters_enabled = true
}

resource "oci_devops_deploy_pipeline" "mushop_deploy_pipeline" {
  project_id   = oci_devops_project.mushop_devops_project.id
  display_name = "mushop-deploy"
  deploy_pipeline_parameters {
    items {
      name          = "ENFORCE_HELM_DEPLOYMENT"
      default_value = true
    }
  }
}

resource "oci_devops_deploy_environment" "mushop_env" {
  project_id              = oci_devops_project.mushop_devops_project.id
  display_name            = "mushop-oke"
  deploy_environment_type = "OKE_CLUSTER"
  cluster_id              = oci_containerengine_cluster.mushop_oke.id
}

resource "oci_devops_deploy_stage" "mushop_setup_stage" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.mushop_deploy_pipeline.id
  display_name       = "mushop-setup"
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.mushop_deploy_pipeline.id
    }
  }
  deploy_stage_type                 = "OKE_HELM_CHART_DEPLOYMENT"
  helm_chart_deploy_artifact_id     = oci_devops_deploy_artifact.mushop_setup_artifact.id
  release_name                      = "mushop-utilities"
  are_hooks_enabled                 = true
  oke_cluster_deploy_environment_id = oci_devops_deploy_environment.mushop_env.id
  namespace                         = "mushop"
}

resource "oci_devops_deploy_stage" "mushop_deploy" {
  deploy_pipeline_id = oci_devops_deploy_pipeline.mushop_deploy_pipeline.id
  display_name       = "deploy"
  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_stage.mushop_setup_stage.id
    }
  }
  deploy_stage_type                 = "OKE_HELM_CHART_DEPLOYMENT"
  helm_chart_deploy_artifact_id     = oci_devops_deploy_artifact.mushop_deploy_artifact.id
  release_name                      = "mushop"
  oke_cluster_deploy_environment_id = oci_devops_deploy_environment.mushop_env.id
  namespace                         = "mushop"
}
