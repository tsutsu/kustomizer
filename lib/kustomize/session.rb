module Kustomize; end

require 'kustomize/plugin_manager'

class Kustomize::Session
  def initialize(load_paths: [])
    @load_paths = load_paths
    @plugin_manager = Kustomize::PluginManager.new(session: self)
  end

  attr_reader :plugin_manager

  def builtin_load_paths
    [Pathname.new(__FILE__).expand_path.parent / 'builtin_plugins']
  end

  def effective_load_paths
    @load_paths + self.builtin_load_paths
  end
end
