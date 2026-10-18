require "test_helper"

# The next-redirect rule on its own. Each unsafe value here is a way of writing
# "somewhere else" that still starts with a slash, which is what makes a naive
# "does it begin with /" check insufficient.
class SafeRedirectTest < ActionDispatch::IntegrationTest
  SAFE = [
    "/",
    "/exercises",
    "/exercises/merge-intervals",
    "/?difficulty=hard&topic=systems",
    "/exercises/a-b_c.d~e"
  ].freeze

  UNSAFE = [
    "//evil.test",                      # protocol-relative: a host, not a path
    "//evil.test/exercises",
    "https://evil.test",                # absolute
    "http://evil.test",
    "/\\evil.test",                     # backslash, normalised to / by some parsers
    "/\\/evil.test",
    "javascript:alert(1)",              # not a path at all
    "evil.test",                        # relative, resolves against the current page
    "exercises",
    "/exercises\nLocation: https://evil.test",   # header injection
    "/exercises\r\nSet-Cookie: a=b",
    ""
  ].freeze

  def signed_in_landing_for(next_param)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: "9000002",
      info: { nickname: "tester", name: "Tester", image: nil }
    )

    get sign_in_path(next: next_param)
    post github_auth_path

    # In test mode the request phase redirects through the callback, so the
    # chain is longer than one hop. Follow it until it settles.
    6.times do
      break unless response.redirect?
      follow_redirect!
    end

    # fullpath, not path: path drops the query string, which several of the
    # safe candidates rely on.
    request.fullpath
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "a safe relative path is honoured after signing in" do
    SAFE.each do |candidate|
      reset!
      assert_equal candidate, signed_in_landing_for(candidate),
        "expected #{candidate.inspect} to be kept"
    end
  end

  test "anything that could leave the site is ignored in favour of the library" do
    UNSAFE.each do |candidate|
      reset!
      assert_equal root_path, signed_in_landing_for(candidate),
        "expected #{candidate.inspect} to be dropped"
    end
  end

  test "no next parameter lands on the library" do
    reset!
    assert_equal root_path, signed_in_landing_for(nil)
  end

  # A fragment is legitimate in a next parameter, but a browser never sends one
  # to the server, so it can only be observed on the Location header rather than
  # on the request that follows it.
  test "a fragment is preserved in the redirect itself" do
    reset!
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github", uid: "9000003",
      info: { nickname: "tester", name: "Tester", image: nil }
    )

    get sign_in_path(next: "/exercises/merge-intervals#the-problem")
    post github_auth_path
    follow_redirect!   # the request phase hands off to the callback

    assert_match "/exercises/merge-intervals#the-problem", response.location
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end
end
