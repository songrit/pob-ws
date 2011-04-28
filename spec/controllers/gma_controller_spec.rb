require 'spec_helper'

describe GmaController do
  integrate_views

  it "should annotate"
  it "setup Time::DATE_FORMATS[:th]  http://localhost/doc/railsbrain/index.html?a=M001522&name=to_formatted_s"
  it "use formtastic"

  it "should show log" do
    controller.stub(:admin?).and_return(true)
    get :logs
    response.should be_success
  end
end