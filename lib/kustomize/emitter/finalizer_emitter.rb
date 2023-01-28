require 'kustomize/emitter'

require 'kustomize/transform/fingerprint_suffix_transform'
require 'kustomize/transform/ref_fixup_transform'
require 'kustomize/transform/filter_for_session_specified_component_transform'
require 'kustomize/transform/drop_filtered_documents_transform'
require 'kustomize/transform/purge_internal_annotations_transform'
require 'kustomize/transform/application_order_transform'

class Kustomize::Emitter::FinalizerEmitter < Kustomize::Emitter
  def initialize(input_emitter, session:)
    @input_emitter = input_emitter
    @session = session
  end

  def input_emitters
    [@input_emitter]
  end

  def transforms
    return @transforms if @transforms

    final_filters =
      if comp = @session.only_emit_component
        [Kustomize::Transform::FilterForSessionSpecifiedComponentTransform.create(comp)]
      else
        []
      end

    @transforms = [
      Kustomize::Transform::FingerprintSuffixTransform.instance,
      Kustomize::Transform::RefFixupTransform.instance,
      final_filters,
      Kustomize::Transform::DropFilteredDocumentsTransform.instance,
      Kustomize::Transform::PurgeInternalAnnotationsTransform.instance,
      Kustomize::Transform::ApplicationOrderTransform.instance
    ].flatten.compact
  end

  def emit
    self.transforms.inject(self.input_resources) do |rcs, xform|
      xform.rewrite_all(rcs)
    end
  end
end
