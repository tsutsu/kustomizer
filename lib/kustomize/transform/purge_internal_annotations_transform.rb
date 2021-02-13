require 'singleton'

require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::PurgeInternalAnnotationsTransform < Kustomize::Transform
  include Accessory
  include Singleton

  LENSES = [
    Lens['metadata', 'annotations'],
    Lens['spec', 'template', 'metadata', 'annotations'],
    Lens['spec', 'jobTemplate', 'spec', 'template', 'metadata', 'annotations']
  ]

  INTERNAL_ANNOT_PATTERNS = [
    /^config\.kubernetes\.io\//,
    /^kustomizer\.covalenthq\.com\//
  ]

  def rewrite(rc_doc)
    LENSES.inject(rc_doc) do |doc, lens|
      lens.update_in(rc_doc) do |orig_annots|
        next(:keep) unless orig_annots and orig_annots.length.nonzero?

        new_annots =
          orig_annots.reject{ |k, v| INTERNAL_ANNOT_PATTERNS.any?{ |pat| pat.match?(k) } }

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
end
