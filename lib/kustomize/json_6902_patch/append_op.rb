require 'kustomize/json_6902_patch'

class Kustomize::Json6902Patch::AppendOp < Kustomize::Json6902Patch::Op
  def self.create(patch_spec)
    elements =
      if e = patch_spec['element']
        [e]
      elsif es = patch_spec['elements']
        es
      else
        raise ArgumentError, "must specify one of 'element' or 'elements' in: #{patch_spec.inspect}"
      end

    new(
      array_path: patch_spec['path'],
      elements: elements
    )
  end

  def initialize(array_path:, elements:)
    @lens = parse_lens(array_path)
    @new_elements = elements
  end

  def apply(rc)
    @lens.update_in(rc) do |orig_arr|
      new_arr = orig_arr.dup || []

      @new_elements.each do |elem|
        new_arr.push(elem)
      end

      [:set, new_arr]
    end
  end
end
