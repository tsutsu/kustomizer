module Kustomize; end

class Kustomize::Transform
  def self.create(...)
    new(...)
  end

  class << self
    private :new
  end

  def rewrite_all(rcs)
    rcs.map{ |rc| rewrite(rc) }
  end

  def rewrite(rc)
    rc
  end
end
