require 'kustomize/emitter'

class Kustomize::Emitter::GeneratorPluginsEmitter < Kustomize::Emitter
  def initialize(plugin_rc_emitters, session:)
    @session = session
    @plugin_rc_emitters = plugin_rc_emitters
  end

  def plugin_rcs
    @plugin_rc_emitters.flat_map(&:emit)
  end

  def plugin_instances
    return @plugin_instances if @plugin_instances

    @plugin_instances =
      self.plugin_rcs.map do |rc|
        plugin_klass = @session.plugin_manager.get(api_version: rc['apiVersion'], kind: rc['kind'])
        plugin_klass.create(rc, session: @session)
      end
  end

  def emit
    self.plugin_instances.flat_map(&:emit)
  end
end
