require 'singleton'

require 'kustomize/plugin_registry'

class Kustomize::PluginManager
  def initialize(session:)
    @session = session
    @registry = Kustomize::PluginRegistry.instance
  end

  def get(api_version:, kind:)
    plugin_klass = @registry.get(api_version: api_version, kind: kind)
    return plugin_klass if plugin_klass

    try_loading(api_version, kind)
  end

  private
  def try_loading(api_version, kind)
    rel_load_path = Pathname.new(api_version) / "#{underscore(kind)}.rb"

    abs_load_path =
      @session.effective_load_paths
      .map{ |prefix| prefix / rel_load_path }
      .find{ |f| f.file? }

    raise LoadError, "could not find kustomize plugin to load" unless abs_load_path

    Kernel.require(abs_load_path)

    plugin_klass = @registry.get(api_version: api_version, kind: kind)

    raise LoadError, "#{abs_load_path} did not define expected plugin" unless plugin_klass

    plugin_klass
  end

  private
  def underscore(str)
    str
    .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    .gsub(/([a-z\d])([A-Z])/,'\1_\2')
    .tr("-", "_")
    .downcase
  end
end
