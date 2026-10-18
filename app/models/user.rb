class User < ApplicationRecord
  # Append-only history, so a user's attempts are destroyed with them. The
  # database carries the same rule (on_delete: :cascade) for deletes that never
  # pass through Active Record.
  has_many :attempts, dependent: :destroy

  # Signing out everywhere, and deleting a user, both have to take the sessions
  # with them. The database carries the same rule for deletes that never pass
  # through Active Record.
  has_many :sessions, dependent: :destroy
  has_many :exercises, -> { distinct }, through: :attempts

  validates :github_id, presence: true, uniqueness: true
  validates :login, presence: true

  # Identity is github_id and nothing else: a GitHub user can rename themselves,
  # and the row has to follow them rather than fork. login, name and avatar are
  # refreshed on every sign-in because they are GitHub's to change, not ours.
  def self.from_github(auth)
    user = find_or_initialize_by(github_id: auth.github_id)
    user.login = auth.login
    user.name = auth.name
    user.avatar_url = auth.avatar_url
    user.save!
    user
  end

  def display_name
    name.presence || login
  end
end
