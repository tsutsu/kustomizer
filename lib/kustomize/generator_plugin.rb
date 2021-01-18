require 'kustomize/plugin'

class Kustomize::GeneratorPlugin < Kustomize::Plugin
  def self.inherited(subklass)
    reg = Kustomize::PluginRegistry.instance
    reg.probe_queue.push(subklass)
  end

  def emit
    []
  end

  def to_yaml_stream
    self.emit.map(&:to_yaml).join("")
  end
end
