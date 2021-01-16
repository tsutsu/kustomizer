# frozen_string_literal: true

RSpec.describe Kustomize do
  it "has a version number" do
    expect(Kustomize::VERSION).not_to be nil
  end
end
