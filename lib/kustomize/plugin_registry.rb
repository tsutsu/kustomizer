require 'singleton'

module Kustomize; end

class Kustomize::PluginRegistry
  include Singleton

  def initialize
    @klasses = {}
    @probe_queue = []
  end

  attr_reader :probe_queue

  def get(api_version:, kind:)
    drain_probe_queue!

    rc_target_id = make_rc_target_id(api_version, kind)
    @klasses[rc_target_id]
  end

  private
  def drain_probe_queue!
    return if @probe_queue.empty?

    while plugin_klass = @probe_queue.shift
      rc_target_id = make_rc_target_id(
        plugin_klass.kustomize_plugin_match_api_version,
        plugin_klass.kustomize_plugin_match_kind
      )
      @klasses[rc_target_id] = plugin_klass
    end
  end

  private
  def make_rc_target_id(api_version, kind)
    [api_version, kind].join('/').to_s.intern
  end
end
