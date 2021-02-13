module Kustomize; end

require 'kustomize/plugin_manager'

class Kustomize::Session
  def initialize(load_paths: [], only_emit_component: nil)
    @load_paths = load_paths
    @plugin_manager = Kustomize::PluginManager.new(session: self)
    @only_emit_component = only_emit_component
  end

  attr_reader :plugin_manager
  attr_accessor :only_emit_component

  def builtin_load_paths
    [Pathname.new(__FILE__).expand_path.parent / 'builtin_plugins']
  end

  def effective_load_paths
    @load_paths + self.builtin_load_paths
  end
end
