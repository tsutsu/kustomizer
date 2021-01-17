require 'json'
require 'digest'
require 'set'

require 'accessory'
require 'digest/base32'

require 'kustomize/transform'
require 'kustomize/emitter/document_emitter/kustomization_document_emitter'

class Kustomize::Transform::NameDigestAutosuffixTransform < Kustomize::Transform
  include Accessory

  SUFFIX_JOINER = "-"

  def self.create(kustomize_doc)
    raise ArgumentError unless kustomize_doc.kind_of?(Kustomize::Emitter::DocumentEmitter::KustomizationDocumentEmitter)
    self.new(kustomize_doc)
  end

  def initialize(kustomize_doc)
    @kustomize_doc = kustomize_doc
  end

  SECRET_KINDS = Set[
    'Secret',
    'SealedSecret'
  ]

  SECRET_NAME_LENS = Lens["metadata", "name"]

  SECRET_CONTENT_LENS_BY_KIND = {
    "Secret" => Lens["data"],
    "SealedSecret" => Lens["spec", "encryptedData"]
  }

  NAME_REF_LENSES_BY_KIND = {
    "Deployment" => [
      Lens["spec", "template", "spec", "containers", Access.all, "env", Access.all, "valueFrom", "secretKeyRef", "name"]
    ]
  }

  def rewrite_all(rcs)
    rcs_grouped_by_secretness = rcs.group_by{ |rc| SECRET_KINDS.member?(rc['kind']) }
    secret_rcs = rcs_grouped_by_secretness[true] || []
    nonsecret_rcs = rcs_grouped_by_secretness[false] || []

    suffixes = secret_rcs.map do |rc|
      rc_kind = rc['kind']

      secret_name = SECRET_NAME_LENS.get_in(rc)
      secret_content = SECRET_CONTENT_LENS_BY_KIND[rc_kind].get_in(rc)
      content_hash_suffix = Digest::SHA256.base32digest(secret_content.to_json, :zbase32)[0, 8]

      [secret_name, content_hash_suffix]
    end.to_h

    rcs.map do |rc|
      name_ref_lenses = NAME_REF_LENSES_BY_KIND[rc['kind']]
      next(rc) unless name_ref_lenses

      name_ref_lenses.inject(rc) do |doc, lens|
        lens.update_in(doc) do |orig_name|
          if suffixes.has_key?(orig_name)
            new_name = [orig_name, suffixes[orig_name]].join('-')
            [:set, new_name]
          else
            :keep
          end
        end
      end
    end
  end
end
