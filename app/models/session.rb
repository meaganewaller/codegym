class Session < ApplicationRecord
  # An absolute lifetime, not a rolling one: a session is good for this long
  # from the moment it was created, however active it has been. Rails' own
  # authentication generator leaves sessions immortal, which is fine for an
  # app that can revoke them by hand and wrong for one that cannot.
  MAX_AGE = 30.days

  belongs_to :user

  scope :active, -> { where(created_at: MAX_AGE.ago..) }
  scope :newest_first, -> { order(created_at: :desc) }

  def expired?
    created_at <= MAX_AGE.ago
  end
end
