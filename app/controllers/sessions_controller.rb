class SessionsController < ApplicationController
  # The sign-in page itself cannot require a sign-in, and neither can the
  # callback GitHub sends the browser back to.
  def new
    return redirect_to root_path if signed_in?

    # Where to go after signing in. Taken from the query string so a link into
    # a page that needs an account can carry its destination, and filtered to a
    # same-site relative path before it is stored -- an unsafe value is dropped
    # rather than corrected, so the fallback is the library.
    session[:return_to] = safe_return_path(params[:next])
  end

  # GitHub has sent the browser back. OmniAuth has already exchanged the code
  # for a token and verified the state parameter it set on the request phase;
  # a tampered or missing state never reaches here, it goes to failure.
  def create
    identity = GithubIdentity.from_omniauth(request.env["omniauth.auth"])
    user = User.from_github(identity)

    start_new_session_for(user)
    redirect_to after_authentication_path, notice: "Signed in as #{user.display_name}."
  rescue GithubIdentity::InvalidIdentity => error
    # GitHub told us something we will not build an account from.
    logger.warn "Rejected a GitHub identity: #{error.message}"
    redirect_to sign_in_path, alert: "GitHub did not send enough information to sign you in."
  end

  # Where OmniAuth sends a denial, a tampered state, or a provider error. The
  # reason is a short machine string from OmniAuth, never anything a user typed,
  # so it is safe to log but not worth showing.
  def failure
    logger.info "GitHub sign-in failed: #{params[:message]}"
    redirect_to sign_in_path, alert: "Sign-in was cancelled or could not be completed."
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Signed out."
  end

  # OmniAuth's middleware intercepts POST /auth/github before routing, so this
  # never runs. The route exists so the form has a named path to post to.
  def passthru
    head :not_found
  end
end
