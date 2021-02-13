require 'accessory'

require 'kustomize/transform'

class Kustomize::Transform::CommonLabelsTransform < Kustomize::Transform
  include Accessory

  def initialize(new_labels)
    @new_labels = new_labels
  end

  LENSES_FOR_ALL = [
    Lens["metadata", "labels"]
  ]

  LENSES_FOR_KIND = {
    "Service" => [
      Lens["spec", "selector"]
    ],

    "Deployment" => [
      Lens["spec", "selector", "matchLabels"]
    ],
  }

  def rewrite(rc_doc)
    rc_kind = rc_doc['kind']
    use_lenses = LENSES_FOR_ALL

    if lenses_for_doc_kind = LENSES_FOR_KIND[rc_kind]
      use_lenses += lenses_for_doc_kind
    end

    use_lenses.inject(rc_doc) do |doc, lens|
      lens.update_in(doc) do |annots|
        [:set, (annots || {}).merge(@new_labels)]
      end
    end
  end

end
