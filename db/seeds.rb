unless GmaUser.exists?(:login=>"anonymous")
  GmaUser.create :login=>"anonymous"
end
unless GmaUser.exists?(:login=>"songrit")
  GmaUser.create :login=>"songrit", :password=>"aa",
  :email=>"songrit@gmail.com", :role=>"M,A,D",
  :fname=>"songrit", :lname=>"leemakdej", :cellphone => "083-788-7769",
  :org=>"GMindApp"
end