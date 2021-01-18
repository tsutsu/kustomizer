require 'kustomize/generator_plugin'

module CovalentKustomizer; end

class CovalentKustomizer::TestGenerator < Kustomize::GeneratorPlugin
  match_on api_version: 'kustomizer.covalenthq.com/v1'

  def initialize(rc)
    @docs = rc['emit'] || []
  end

  def emit
    @docs
  end
end
