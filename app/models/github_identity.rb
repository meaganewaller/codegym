# Everything we are willing to believe about a person from one GitHub sign-in.
#
# This exists so OmniAuth's hash shape stops at the door. Controllers and User
# see github_id, login, name and avatar_url; if the provider or the gem changes
# where those live, only this file moves.
class GithubIdentity
  class InvalidIdentity < StandardError; end

  def self.from_omniauth(auth)
    info = auth.info || {}

    new(
      # OmniAuth hands back uid as a String. The column is a bigint, and a cast
      # of something non-numeric would quietly become nil and then fail on NOT
      # NULL far from the cause, so it is parsed strictly here instead.
      github_id: parse_id(auth.uid),
      login: info[:nickname].presence,
      name: info[:name].presence,
      avatar_url: info[:image].presence
    )
  end

  def self.parse_id(uid)
    Integer(uid.to_s, 10)
  rescue ArgumentError, TypeError
    raise InvalidIdentity, "GitHub returned a uid that is not a number"
  end

  attr_reader :github_id, :login, :name, :avatar_url

  def initialize(github_id:, login:, name: nil, avatar_url: nil)
    @github_id = github_id
    @login = login
    @name = name
    @avatar_url = avatar_url

    # A sign-in with no login is not something to paper over with a placeholder:
    # the column is NOT NULL and the name is shown to the user.
    raise InvalidIdentity, "GitHub returned no login" if login.blank?
  end
end
