When /^the application issues an? "([A-Z]+)" request for "([^"]*)"$/ do |method, url|
  case method
  when "GET"
    get :from => url
  when "POST"
    post :to => url
  when "DELETE"
    delete :at => url
  when "PUT"
    put :to => url
  else
    method.should == "unsupported HTTP method"
  end
end

When /^the application issues an? "([A-Z]+)" request to the mock$/ do |method|
  When %{the application issues a "#{method}" request for "/service"}
end

Then /^the response code should be "(\d+)"$/ do |expected|
  response.code.should == expected.to_i
end

Then /^the response "([^"]*)" header should be "([^"]*)"$/ do |header, expected|
  response.headers[header].should match(expected)
end

Then /^the response body should be:$/ do |expected|
  response.body.should == expected
end
