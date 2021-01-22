require 'singleton'

require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::PurgeInternalAnnotationsTransform < Kustomize::Transform
  include Accessory
  include Singleton

  ANNOTS_LENS = Lens['metadata', 'annotations']

  INTERNAL_ANNOT_PATTERN = /^kustomizer\.covalenthq\.com\//

  def rewrite(rc)
    ANNOTS_LENS.update_in(rc) do |orig_annots|
      next(:keep) unless orig_annots and orig_annots.length.nonzero?

      new_annots =
        orig_annots.reject{ |k, v| INTERNAL_ANNOT_PATTERN.match?(k) }

      if new_annots.length == orig_annots.length
        :keep
      elsif new_annots.empty?
        :pop
      else
        [:set, new_annots]
      end
    end
  end
end
