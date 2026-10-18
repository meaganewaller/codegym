# Adapted from the pieces of Rails' authentication generator worth keeping:
# a Session row, Current, and a resume/start/terminate trio. The password flow
# is gone, because the only way in is GitHub.
#
# Two things differ from the generated version. Sessions expire (Session::MAX_AGE),
# and pages are public by default: this app has a library anyone may read, so
# requiring authentication everywhere and opting out page by page would be the
# wrong way round.
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :signed_in?, :current_user
  end

  class_methods do
    def require_sign_in(**options)
      before_action :require_authentication, **options
    end
  end

  private
    def signed_in?
      resume_session.present?
    end

    def current_user
      Current.user
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # Scoped to active, so an expired row is treated exactly like a missing one.
    # A forged or tampered cookie fails the signature and arrives here as nil,
    # and a revoked session is a row that is no longer there.
    def find_session_by_cookie
      token = cookies.signed[:session_id]
      Session.active.find_by(id: token) if token
    end

    def request_authentication
      session[:return_to] = safe_return_path(request.fullpath)
      redirect_to sign_in_path
    end

    def after_authentication_path
      safe_return_path(session.delete(:return_to)) || root_path
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |record|
        Current.session = record

        # httponly keeps it away from JavaScript; same_site: :lax still sends it
        # on a top-level GET back from GitHub, which is how the callback works.
        # Signed, so the row id cannot be swapped for someone else's.
        cookies.signed.permanent[:session_id] = {
          value: record.id, httponly: true, same_site: :lax, secure: request.ssl?
        }
      end
    end

    def terminate_session
      # Resume first: Current.session is only populated by resume_session, and
      # without this the cookie was cleared while the row lived on -- a session
      # that looks signed out but is still valid to anyone holding the cookie.
      resume_session
      Current.session&.destroy
      Current.session = nil
      cookies.delete(:session_id)
    end

    # Only a path on this site, and only one that cannot be read as a host.
    #
    # "//evil.test" is protocol-relative and goes off-site; "/\evil.test" is the
    # same trick with a backslash, which some parsers normalise to a slash.
    # Anything that is not a plain relative path is dropped rather than
    # corrected, because a redirect target is not worth guessing at.
    SAFE_PATH = %r{\A/(?![/\\])[^\\\r\n]*\z}

    def safe_return_path(value)
      value.presence&.match?(SAFE_PATH) ? value : nil
    end
end
