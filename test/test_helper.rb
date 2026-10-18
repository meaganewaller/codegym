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
  end
end

# Signing in through the real OmniAuth path, in test mode, so tests exercise
# the same callback and session creation the browser does rather than reaching
# past it and stuffing a cookie.
module SignInHelper
  def sign_in_as(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: user.github_id.to_s,
      info: { nickname: user.login, name: user.name, image: user.avatar_url }
    )

    post "/auth/github"
    follow_redirect! while response.redirect?
    user
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
