require 'singleton'
require 'set'

require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::DropFilteredDocumentsTransform < Kustomize::Transform
  include Accessory
  include Singleton

  ANNOTS_LENS = Lens['metadata', 'annotations']

  DROP_ON_ANNOTS = Set[
    'config.kubernetes.io/local-config',
    'kustomizer.covalenthq.com/drop'
  ]

  def rewrite_all(rcs)
    rcs.filter do |rc|
      annot_keys = (ANNOTS_LENS.get_in(rc) || {}).keys
      not(annot_keys.find{ |k| DROP_ON_ANNOTS.member?(k) })
    end
  end
end
