require 'kustomize/emitter'

require 'kustomize/transform/fingerprint_suffix_transform'
require 'kustomize/transform/ref_fixup_transform'
require 'kustomize/transform/purge_internal_annotations_transform'

class Kustomize::Emitter::FinalizerEmitter < Kustomize::Emitter
  def initialize(input_emitter)
    @input_emitter = input_emitter
  end

  def input_emitters
    [@input_emitter]
  end

  def transforms
    return @transforms if @transforms

    @transforms = [
      Kustomize::Transform::FingerprintSuffixTransform.instance,
      Kustomize::Transform::RefFixupTransform.instance,
      Kustomize::Transform::PurgeInternalAnnotationsTransform.instance
    ].flatten
  end

  def emit
    self.transforms.inject(self.input_resources) do |rcs, xform|
      xform.rewrite_all(rcs)
    end
  end
end
