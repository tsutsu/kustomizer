require 'json'
require 'digest'
require 'set'
require 'singleton'

require 'accessory'
require 'digest/base32'

require 'kustomize/transform'

class Kustomize::Transform::FingerprintSuffixTransform < Kustomize::Transform
  include Accessory
  include Singleton

  SUFFIX_JOINER = "-"

  APPLICABLE_KINDS = Set[
    'Secret',
    'SealedSecret',
    'ConfigMap'
  ]

  NAME_LENS = Lens["metadata", "name"]

  CONTENT_LENS_BY_KIND = {
    "Secret" => Lens["data"],
    "ConfigMap" => Lens["data"],
    "SealedSecret" => Lens["spec", "encryptedData"]
  }

  FINGERPRINT_LENS = Lens['metadata', 'annotations', 'kustomizer.covalenthq.com/effective-fingerprint']

  def rewrite(rc)
    rc_kind = rc['kind']
    return rc unless APPLICABLE_KINDS.member?(rc_kind)

    FINGERPRINT_LENS.update_in(rc) do |orig_value|
      if orig_value
        if orig_value == ''
          next(:pop)
        else
          next(:keep)
        end
      end

      content_part = CONTENT_LENS_BY_KIND[rc_kind].get_in(rc)
      content_ser = content_part.to_json
      fingerprint = Digest::SHA256.base32digest(content_ser, :zbase32)[0, 6]

      [:set, fingerprint]
    end

    base_name = NAME_LENS.get_in(rc)
    fingerprint = FINGERPRINT_LENS.get_in(rc)

    if fingerprint
      NAME_LENS.update_in(rc) do |base_name|
        suffixed_name = [base_name, fingerprint].join(SUFFIX_JOINER)
        [:set, suffixed_name]
      end
    end

    rc
  end
end
