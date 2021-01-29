require 'singleton'

require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::RefFixupTransform < Kustomize::Transform
  include Accessory
  include Singleton

  SUFFIX_JOINER = "-"

  NAME_LENS = Lens["metadata", "name"]

  FINGERPRINT_LENS = Lens['metadata', 'annotations', 'kustomizer.covalenthq.com/effective-fingerprint']

  POD_TEMPLATE_LENSES = [
      Lens["spec", "template", "spec", "containers", Access.all, "envFrom", Access.all, "configMapRef", "name"],
      Lens["spec", "template", "spec", "containers", Access.all, "env", Access.all, "valueFrom", "configMapKeyRef", "name"],
      Lens["spec", "template", "spec", "volumes", Access.all, "configMap", "name"],

      Lens["spec", "template", "spec", "containers", Access.all, "env", Access.all, "valueFrom", "secretKeyRef", "name"],
      Lens["spec", "template", "spec", "volumes", Access.all, "secret", "name"],
      Lens["spec", "template", "spec", "volumes", Access.all, "secret", "secretName"]
  ]

  KEY_REF_LENSES_BY_KIND = {
    "Deployment" => POD_TEMPLATE_LENSES,
    "StatefulSet" => POD_TEMPLATE_LENSES,
    "DaemonSet" => POD_TEMPLATE_LENSES
  }

  def rewrite_all(rcs)
    ref_fixups =
      rcs.flat_map do |rc|
        fingerprint = FINGERPRINT_LENS.get_in(rc)
        next([]) unless fingerprint

        suffixed_name = NAME_LENS.get_in(rc)
        base_name = suffixed_name.gsub(/-#{fingerprint}$/, '')
        [[base_name, suffixed_name]]
      end.to_h

    rcs.map do |rc|
      key_ref_lenses = KEY_REF_LENSES_BY_KIND[rc['kind']]
      next(rc) unless key_ref_lenses

      key_ref_lenses.inject(rc) do |doc, lens|
        lens.update_in(doc) do |base_name|
          if suffixed_name = ref_fixups[base_name]
            [:set, suffixed_name]
          else
            :keep
          end
        end
      end
    end
  end
end
