require 'kustomize/transformer_plugin'

module CovalentKustomizer; end

class CovalentKustomizer::TestTransformer < Kustomize::TransformerPlugin
  match_on api_version: 'kustomizer.covalenthq.com/v1'

  def initialize(rc)
    @insertions = rc['insert'] || {}
  end

  def rewrite(rc)
    rc.merge(@insertions)
  end
end
