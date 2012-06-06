# Harper: Dead-simple, out-of-process, HTTP mocks

To mock a service using as Harper, POST a mock definition to Harper
before making your request. It's simple, and you've probably written
something similar a half-dozen times. Well, you don't need to anymore.

You might be interested in using Harper when you're building an app
that depends on an HTTP service, but you can't mock it out
in-process. For example, a single page JavaScript app running in a
mobile browser.

## Ruby Client API

Unfortunately there aren't yet interfaces to Harper from other languages.

* Use `HarperClient::start` to start the Harper service in the
  background.

* Use `HarperClient::stop` to stop the background service.

These two calls do start and stop another Ruby interpreter running in
the background, so you might want to run these at the beginning and
the end of your cucumber run, rather than before and after every
scenario.

This interface is incomplete. It is also possible to delete a
mock. This can be done by deleting the URL provided in the `Location`
header when creating a new mock.

If you require more control of Harper, or you want to support a new
language, check out `features/mock_http_rpc_service.feature`. And pull
requests are always welcomed.

### Defining Mocks

Use `HarperClient::mock` to define a new mock. This method takes a
hash defining the mock. If a mock has already been defined for a URL,
Harper will silently replace it with the new mock.

* *url*: The URL path to mock out. This also identifies the mock. Required.
* *method*: The HTTP method to respond to. Required.

* *status*: The HTTP status code to provide. Optional. Defaults to 200.
* *content_type*: What content-type header to set when responding with
   the mock. Required.
* *body*: Either a string to be used as the HTTP response body, or an
   array of strings. If an array is provided Harper will cycle through
   the array as the response body for requests. Required.

* *delay*: A delay to include when responding to the mock,
   in milliseconds. Optional. Defaults to no delay.

## Typical Use

1. Start Harper at the very start of your test run.
2. In the Given steps or Background for your scenarios, define the
mocks that will be required for that scenario. If a similar mock has
already been defined, Harper will silently replace it.
3. At the very end of your test run, stop Harper.

That's it.
