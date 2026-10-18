require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = nil
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:github] = nil
  end

  def github_auth(uid: "9000001", nickname: "meaganewaller", name: "Meagan", image: "https://avatars.test/m.png")
    OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: { nickname: nickname, name: name, image: image }
    )
  end

  def sign_in_with(auth = github_auth)
    OmniAuth.config.mock_auth[:github] = auth
    post github_auth_path
    follow_redirect!
  end

  # Failure chains differ in length: in test mode the request phase redirects
  # through the callback before reaching /auth/failure, so counting hops is
  # brittle. Follow until it settles and assert where it landed.
  def follow_redirects!(limit: 6)
    limit.times do
      break unless response.redirect?
      follow_redirect!
    end
    assert_not_predicate response, :redirect?, "still redirecting after #{limit} hops"
  end

  # --- signing in -----------------------------------------------------------

  test "signing in creates the user and a session" do
    assert_difference [ "User.count", "Session.count" ], 1 do
      sign_in_with
    end

    user = User.find_by!(github_id: 9_000_001)
    assert_equal "meaganewaller", user.login
    assert_equal "Meagan", user.name
    assert_equal "https://avatars.test/m.png", user.avatar_url
  end

  test "signing in lands on the library and says who you are" do
    sign_in_with
    follow_redirect!

    assert_response :success
    assert_select ".topbar__who", text: /Meagan/
  end

  # Identity is github_id: a renamed GitHub account must keep its row and its
  # attempts rather than forking into a second user.
  test "signing in again as a renamed account updates rather than duplicates" do
    existing = users(:meagan)

    assert_no_difference "User.count" do
      sign_in_with github_auth(uid: existing.github_id.to_s, nickname: "renamed", name: "New Name")
    end

    existing.reload
    assert_equal "renamed", existing.login
    assert_equal "New Name", existing.name
  end

  test "an attempt logged before a rename still belongs to the same user" do
    existing = users(:meagan)
    before = existing.attempts.count

    sign_in_with github_auth(uid: existing.github_id.to_s, nickname: "renamed")

    assert_equal before, existing.reload.attempts.count
  end

  test "a second sign-in adds a session without adding a user" do
    sign_in_with
    reset!
    OmniAuth.config.test_mode = true

    assert_difference "Session.count", 1 do
      assert_no_difference "User.count" do
        sign_in_with
      end
    end
  end

  # --- the sign-in page -----------------------------------------------------

  # POST, not a link: omniauth-rails_csrf_protection checks an authenticity
  # token on the request phase, and that check is what stops a third-party page
  # from signing a visitor into an account of its choosing.
  #
  # The token itself is not asserted here because config/environments/test.rb
  # sets allow_forgery_protection = false, so Rails emits no token field in this
  # environment. Confirmed present in development by rendering the page.
  test "the sign-in control is a POST form" do
    get sign_in_path

    assert_response :success
    assert_select "form[action=?][method=?]", github_auth_path, "post"
    assert_select "a[href=?]", github_auth_path, count: 0
  end

  # Regression: Turbo submits forms with fetch, and the response here is a
  # redirect to github.com, which fetch cannot follow cross-origin. The whole
  # submission dies on CORS before the user ever reaches GitHub, so the request
  # phase has to be a real browser navigation.
  test "the sign-in form opts out of Turbo so the browser navigates" do
    get sign_in_path

    assert_select "form[action=?][data-turbo=?]", github_auth_path, "false"
  end

  # --- failures -------------------------------------------------------------

  test "a denied sign-in is a message, not an error" do
    OmniAuth.config.mock_auth[:github] = :access_denied
    post github_auth_path
    follow_redirects!

    assert_equal sign_in_path, path
    assert_select ".flash--alert"
    assert_equal 0, Session.count
  end

  # OmniAuth turns a tampered or missing state parameter into the same failure
  # path as any other rejection, which is what keeps a forged callback from
  # minting a session.
  test "a tampered state is rejected and creates nothing" do
    OmniAuth.config.mock_auth[:github] = :csrf_detected

    assert_no_difference [ "User.count", "Session.count" ] do
      post github_auth_path
      follow_redirects!
    end

    assert_equal sign_in_path, path
    assert_select ".flash--alert"
  end

  test "hitting the callback directly without going through GitHub signs nobody in" do
    assert_no_difference [ "User.count", "Session.count" ] do
      get "/auth/github/callback"
    end

    assert_nil cookies[:session_id].presence
  end

  test "an identity with no login is refused" do
    assert_no_difference [ "User.count", "Session.count" ] do
      sign_in_with github_auth(nickname: nil)
    end

    assert_redirected_to sign_in_path
  end

  test "an identity with a non-numeric uid is refused" do
    assert_no_difference [ "User.count", "Session.count" ] do
      sign_in_with github_auth(uid: "not-a-number")
    end

    assert_redirected_to sign_in_path
  end

  # --- signing out ----------------------------------------------------------

  test "signing out destroys the session row, not just the cookie" do
    sign_in_with

    assert_difference "Session.count", -1 do
      delete session_path
    end

    follow_redirect!
    assert_select ".topbar__account a", text: "Sign in"
  end

  test "the sign-in page redirects someone who is already signed in" do
    sign_in_with
    get sign_in_path

    assert_redirected_to root_path
  end

  # --- session integrity ----------------------------------------------------

  test "a forged session cookie is ignored" do
    sign_in_with
    delete session_path

    # Not signed: the signature is what makes a session id unforgeable.
    cookies[:session_id] = Session.maximum(:id).to_i + 1
    get root_path

    assert_response :success
    assert_select ".topbar__account a", text: "Sign in"
  end

  test "a revoked session stops working on the next request" do
    sign_in_with
    get root_path
    assert_select ".topbar__who"

    Session.delete_all
    get root_path

    assert_select ".topbar__who", count: 0
    assert_select ".topbar__account a", text: "Sign in"
  end

  test "an expired session is treated as no session" do
    sign_in_with
    get root_path
    assert_select ".topbar__who"

    Session.update_all(created_at: (Session::MAX_AGE + 1.day).ago)
    get root_path

    assert_select ".topbar__who", count: 0
    assert_select ".topbar__account a", text: "Sign in"
  end

  test "a session is not revived by signing out twice" do
    sign_in_with
    delete session_path
    delete session_path

    assert_equal 0, Session.count
  end

  test "deleting a user takes their sessions with them" do
    sign_in_with
    user = User.find_by!(github_id: 9_000_001)

    assert_difference "Session.count", -user.sessions.count do
      user.destroy
    end
  end
end
