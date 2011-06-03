Given /^the following response mock:$/ do |mock|
  mock_body mock
end

Given /^a defined response mock with a "([^"]*)" of "([^"]*)"$/ do |field, value|
  mock_body({ :url => "/service",
    :method => "GET",
    'content-type' => "text/plain",
    :body => "fake body" }.merge(field.to_sym => value).to_json)
  define_mock
end

When /^the application creates the mock$/ do
  define_mock
end

When /^the application removes the mock for "([^"]*)"$/ do |url|
  remove_mock url
end
