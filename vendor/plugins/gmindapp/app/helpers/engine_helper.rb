module EngineHelper
  def currency(num,d_unit,c_unit)
    num_dollar= num.to_i
    num_cent= ((num-num.to_i)*100).to_i
    dollar= num_dollar.en.numwords
    dollar.capitalize!
    dollar.gsub!( /\s+([a-z])/ ) { " "+$1.upcase } if dollar
    cent= num_cent.en.numwords
    cent.capitalize!
    cent.gsub!( /\s+([a-z])/ ) { " "+$1.upcase } if cent
    d_unit = num_dollar==1 ? d_unit : d_unit.pluralize
    c_unit = num_cent==1 ? c_unit : c_unit.pluralize
    "#{dollar} #{d_unit} AND #{cent} #{c_unit}"
  end
end
