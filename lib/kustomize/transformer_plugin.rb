require 'kustomize/plugin'

class Kustomize::TransformerPlugin < Kustomize::Plugin
  def self.inherited(subklass)
    reg = Kustomize::PluginRegistry.instance
    reg.probe_queue.push(subklass)
  end

  def rewrite_all(rcs)
    rcs.map{ |rc| rewrite(rc) }
  end

  def rewrite(rc)
    rc
  end
end
