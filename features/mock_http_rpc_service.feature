Feature: Mock an HTTP RPC web service
  As a developer who cares about feedback cycles
  I want to be able to easily mock service endpoints
  So that I can fluently describe my test scenarios

  Scenario: Submit a simple service request to mock
    Given the following response mock, known as "original":
      """
      {
        "url": "/service",
        "method": "GET",
        "content-type": "text/plain",
        "body": "fake body"
      }
      """
    When  the application POSTs the mock "original" to "/h/mocks"
    Then  the response code should be "201"
    And   the "original" mock is available at the URL in the "Location" header
    When  the application issues a "GET" request for "/service"
    Then  the response code should be "200"
    And   the response "content-type" header should be "text/plain"
    And   the response body should be:
      """
      fake body
      """
    When the application removes the mock "original"
    And  the application issues a "GET" request for "/service"
    Then the response code should be "503"

  Scenario: Cycle through the bodies of a mock
    Given the following response mock, known as "sequential":
      """
      {
        "url": "/sequential",
        "method": "GET",
        "content-type": "text/plain",
        "body": ["body 1", "body 2"]
      }
      """
    When  the application POSTs the mock "sequential" to "/h/mocks"
    And   the application issues a "GET" request for "/sequential"
    Then  the response body should be:
      """
      body 1
      """
    When  the application issues a "GET" request for "/sequential"
    Then  the response body should be:
      """
      body 2
      """
    When  the application issues a "GET" request for "/sequential"
    Then  the response body should be:
      """
      body 1
      """

  Scenario Outline: All HTTP methods can be mocked
    Given a defined response mock with a "method" of "<METHOD>"
    When the application issues a "<METHOD>" request to the mock
    Then the response code should be "200"
  Examples:
    | METHOD |
    | GET    |
    | POST   |
    | DELETE |
    | PUT    |

  Scenario Outline: HTTP status codes can be mocked
    Given a defined response mock with a "status" of "<STATUS>"
    When  the application issues a "GET" request to the mock
    Then  the response code should be "<STATUS>"
  Examples:
    | STATUS |
    |    200 |
    |    201 |
    |    206 |
    |    301 |
    |    304 |
    |    401 |
    |    403 |
    |    404 |
    |    500 |
    |    503 |
    
  Scenario Outline: Responses from the server can be delayed
    Given a defined response mock with a "delay" of "<MILLISECONDS>"
    When  the application issues a "GET" request to the mock
    Then  the response time should be at least "<MILLISECONDS>"
  Examples:
    | MILLISECONDS |
    |            0 |
    |           10 |
    |          100 |
    |         1000 |
