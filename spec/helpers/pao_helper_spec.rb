require 'spec_helper'

describe PaoHelper do

  it "should be included in the object returned by #helper" do
    included_modules = (class << helper; self; end).send :included_modules
    included_modules.should include(PaoHelper)
  end

end
