require 'pathname'

class Kustomize::Plugin
  def self.create(rc, session:)
    inst = new(rc)
    inst.session = session
    inst
  end

  class << self
    private :new
  end

  attr_accessor :session

  def self.match_on(kind: nil, api_version: nil)
    if kind
      @kustomize_plugin_match_kind = kind
    end

    if api_version
      @kustomize_plugin_match_api_version = api_version
    end
  end

  def self.kustomize_plugin_match_kind
    return @kustomize_plugin_match_kind if @kustomize_plugin_match_kind
    self.name.split('::').last
  end

  def self.kustomize_plugin_match_api_version
    return @kustomize_plugin_match_api_version if @kustomize_plugin_match_api_version
    api_dir = Pathname.new(__FILE__).parent
    api_dir.relative_path_from(api_dir.parent.parent).to_s
  end
end
