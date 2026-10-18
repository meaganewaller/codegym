# Sign in with GitHub. See docs/decisions/0004-github-sign-in.md.
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.application.credentials.dig(:github, :client_id),
    Rails.application.credentials.dig(:github, :client_secret),
    # No scopes at all. github_id and login come back from the public profile,
    # so the consent screen asks for nothing beyond it, and a leaked token
    # would grant no more than any signed-out visitor already has.
    scope: ""
end

# POST only, which is the OmniAuth 2 default, stated here because it is load
# bearing: omniauth-rails_csrf_protection verifies the authenticity token on
# the request phase, and a GET request phase would be forgeable.
OmniAuth.config.allowed_request_methods = [ :post ]

# Send failures through the app rather than raising, including in development,
# so a denial is a flash message instead of an exception page.
OmniAuth.config.failure_raise_out_environments = []
