require 'kustomize/emitter/document_emitter'
require 'kustomize/emitter/file_emitter'
require 'kustomize/emitter/directory_emitter'
require 'kustomize/emitter/generator_plugins_emitter'

require 'kustomize/transform/json_6902_patch_transform'
require 'kustomize/transform/image_transform'
require 'kustomize/transform/namespace_transform'
require 'kustomize/transform/fingerprint_suffix_transform'
require 'kustomize/transform/ref_fixup_transform'
require 'kustomize/transform/purge_internal_annotations_transform'
require 'kustomize/transform/transformer_plugins_transform'

class Kustomize::Emitter::DocumentEmitter::KustomizationDocumentEmitter < Kustomize::Emitter::DocumentEmitter
  def source_directory
    @source[:path].parent
  end

  def input_emitters
    return @input_emitters if @input_emitters

    rc_pathspecs =
      (@doc['bases'] || []) +
      (@doc['resources'] || [])

    gen_plugin_pathspecs =
      (@doc['generators'] || [])

    input_emitters = rc_pathspecs.map do |rel_path|
      build_input_emitter(rel_path)
    end

    gen_plugin_rc_emitters = gen_plugin_pathspecs.map do |rel_path|
      build_input_emitter(rel_path)
    end

    unless gen_plugin_rc_emitters.empty?
      gen_plugins_emitter = Kustomize::Emitter::GeneratorPluginsEmitter.new(
        gen_plugin_rc_emitters,
        session: @session
      )

      input_emitters.push(gen_plugins_emitter)
    end

    @input_emitters = input_emitters
  end

  def build_input_emitter(rel_path)
    abs_path = self.source_directory / rel_path

    unless abs_path.exist?
      raise Errno::ENOENT, abs_path.to_s
    end

    if abs_path.file?
      Kustomize::Emitter::FileEmitter.new(abs_path, session: @session)
    elsif abs_path.directory?
      Kustomize::Emitter::DirectoryEmitter.new(abs_path, session: @session)
    else
      raise Errno::EFTYPE, abs_path.to_s
    end
  end
  private :build_input_emitter

  def json_6902_patch_transforms
    ((@doc['patches'] || []) + (@doc['patchesJson6902'] || [])).map do |op_spec|
      Kustomize::Transform::Json6902PatchTransform.create(self, op_spec)
    end
  end

  def image_transforms
    (@doc['images'] || []).map do |op_spec|
      Kustomize::Transform::ImageTransform.create(op_spec)
    end
  end

  def transformer_plugin_transforms
    xformer_plugin_rc_emitters =
      (@doc['transformers'] || []).map do |rel_path|
        build_input_emitter(rel_path)
      end

    if xformer_plugin_rc_emitters.length > 0
      xform = Kustomize::Transform::TransformerPluginsTransform.create(
        xformer_plugin_rc_emitters,
        session: @session
      )

      [xform]
    else
      []
    end
  end

  def namespace_transforms
    if new_ns = @doc['namespace']
      [Kustomize::Transform::NamespaceTransform.create(new_ns)]
    else
      []
    end
  end

  def transforms
    return @transforms if @transforms

    @transforms = [
      self.namespace_transforms,
      self.image_transforms,
      Kustomize::Transform::FingerprintSuffixTransform.instance,
      self.json_6902_patch_transforms,
      self.transformer_plugin_transforms,
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
