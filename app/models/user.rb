class User < ApplicationRecord
  # Append-only history, so a user's attempts are destroyed with them. The
  # database carries the same rule (on_delete: :cascade) for deletes that never
  # pass through Active Record.
  has_many :attempts, dependent: :destroy
  has_many :exercises, -> { distinct }, through: :attempts

  validates :github_id, presence: true, uniqueness: true
  validates :login, presence: true
end
