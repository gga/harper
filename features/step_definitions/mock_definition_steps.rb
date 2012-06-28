Given /^the following response mock, known as "([^"]*)":$/ do |name, mock|
  known_mock name, :body => mock
end

Given /^a defined response mock with a "([^"]*)" of "([^"]*)"$/ do |field, value|
  known_mock "defined", :body => { :url => "/service",
    :method => "GET",
    'content-type' => "text/plain",
    :body => "fake body" }.merge(field.to_sym => value).to_json
  define_mock "defined"
end

When %r{^the application POSTs the mock "([^"]*)" to "/h/mocks"$} do |name|
  define_mock name
end

When /^the application removes the mock "([^"]*)"$/ do |name|
  remove_mock name
end

Then /^the "([^"]*)" mock is available at the URL in the "([^"]*)" header$/ do |name, header|
  id_url = response.headers[header]
  known_mock name, :url => id_url
  get :from => id_url
  response.code.should == 200
end

When /^the application removes all registered mocks$/ do
  delete_all_mocks
end