require 'spec_helper'

describe GmaController do
  integrate_views

  it "should annotate"

  it "should show log" do
    controller.stub(:admin?).and_return(true)
    get :logs
    response.should be_success
  end
end