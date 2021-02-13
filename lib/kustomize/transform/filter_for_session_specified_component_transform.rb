require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::FilterForSessionSpecifiedComponentTransform < Kustomize::Transform
  include Accessory

  def initialize(component_name)
    @component_name = component_name
  end

  ANNOTS_LENS = Lens['metadata', 'annotations']

  COMPONENT_ANNOT_NAME = 'kustomizer.covalenthq.com/component-name'
  DROP_ANNOT_NAME = 'kustomizer.covalenthq.com/drop'

  def rewrite(rc)
    ANNOTS_LENS.update_in(rc) do |orig_annots|
      orig_annots ||= {}

      if orig_annots[COMPONENT_ANNOT_NAME] == @component_name
        :keep
      else
        new_annots = orig_annots.merge({DROP_ANNOT_NAME => 'true'})
        [:set, new_annots]
      end
    end
  end
end
