require 'spec_helper'

describe "/finance/reports" do
  include FinanceHelper
  it "render without error" do
    render
  end
  it "render /finance/daily" do
#    render :template=> "/finance/daily"
  end
end

