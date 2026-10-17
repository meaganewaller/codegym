class Exercise < ApplicationRecord
  DIFFICULTIES = %w[easy medium hard].freeze

  has_many :attempts, dependent: :restrict_with_error

  # Mapped value-to-itself because difficulty is a string column. A bare array
  # would make Rails map each label to its integer position (enum.rb pairs with
  # each_with_index), storing "0" and tripping the check constraint.
  #
  # validate: true turns a bad value into a validation error instead of an
  # ArgumentError, so a tampered form field is a 422 and not a 500. The matching
  # check constraint is the backstop.
  enum :difficulty, DIFFICULTIES.index_by(&:itself), validate: true

  validates :slug, presence: true, uniqueness: true
  validates :title, :summary, :body_md, :topic, presence: true
  validates :minutes, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 600
  }

  # A null or future published_at means hidden: absent here and a 404 on its own
  # page. Scheduled publishing depends on this, so nothing should bypass it.
  scope :published, -> { where(published_at: ..Time.current) }

  def published?
    published_at.present? && published_at <= Time.current
  end
end
