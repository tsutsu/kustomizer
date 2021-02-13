require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::CommonAnnotationsTransform < Kustomize::Transform
  include Accessory

  def initialize(new_annots)
    @new_annots = new_annots
  end

  BASE_LENS = Lens["metadata", "annotations"]

  LENS_PREFIXES = [
    Lens["spec", "template"],
    Lens["spec", "jobTemplate", "spec", "template"]
  ]

  def rewrite(rc_doc)
    rc_doc = BASE_LENS.update_in(rc_doc) do |annots|
      [:set, (annots || {}).merge(@new_annots)]
    end

    LENS_PREFIXES.inject(rc_doc) do |doc, prefix|
      prefix.update_in(rc_doc) do |node|
        next(:keep) unless node.kind_of?(Hash)

        new_node = BASE_LENS.update_in(node) do |annots|
          [:set, (annots || {}).merge(@new_annots)]
        end

        [:set, new_node]
      end
    end
  end
end
