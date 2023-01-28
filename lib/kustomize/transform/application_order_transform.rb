require 'singleton'

require 'kustomize/transform'

class Kustomize::Transform::ApplicationOrderTransform < Kustomize::Transform
  include Singleton

  # order from https://github.com/helm/helm/blob/main/pkg/releaseutil/kind_sorter.go
  KIND_PRIORITIES = [
    "Namespace",
    "NetworkPolicy",
    "ResourceQuota",
    "LimitRange",
    "PodSecurityPolicy",
    "PodDisruptionBudget",
    "ServiceAccount",
    "SealedSecret",
    "Secret",
    "SecretList",
    "ConfigMap",
    "StorageClass",
    "PersistentVolume",
    "PersistentVolumeClaim",
    "CustomResourceDefinition",
    "ClusterRole",
    "ClusterRoleList",
    "ClusterRoleBinding",
    "ClusterRoleBindingList",
    "Role",
    "RoleList",
    "RoleBinding",
    "RoleBindingList",
    "Service",
    "DaemonSet",
    "Pod",
    "ReplicationController",
    "ReplicaSet",
    "Deployment",
    "HorizontalPodAutoscaler",
    "StatefulSet",

    :unknown_kind,

    "Job",
    "CronJob",
    "IngressClass",
    "Ingress",
    "APIService",
  ].each_with_index.to_h

  def rewrite_all(rcs)
    rcs.sort_by do |rc|
      KIND_PRIORITIES[rc['kind']] || KIND_PRIORITIES[:unknown_kind]
    end
  end
end
