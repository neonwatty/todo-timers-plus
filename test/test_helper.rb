ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def sign_in_as(user)
      if is_a?(ActionDispatch::IntegrationTest)
        # Create a session and set the cookie manually for integration tests
        user_session = user.sessions.create!(
          user_agent: "Rails Testing",
          ip_address: "127.0.0.1"
        )
        # Use the built-in session mechanism for integration tests
        cookies.signed[:session_id] = user_session.id
      else
        # For controller tests, we need to create a session and set the cookie
        user_session = user.sessions.create!(
          user_agent: "Rails Testing",
          ip_address: "127.0.0.1"
        )
        cookies.signed[:session_id] = user_session.id
        Current.session = user_session
      end
    end

    def sign_out
      if is_a?(ActionDispatch::IntegrationTest)
        delete session_url
      else
        cookies.delete(:session_id)
        Current.reset
      end
    end
  end
end
