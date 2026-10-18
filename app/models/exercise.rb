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

  scope :newest_first, -> { order(published_at: :desc) }

  # An unknown value matches nothing rather than raising, so a hand-edited query
  # string shows the empty state instead of a 500. Blank means "no filter",
  # which is what an absent param and the "All" chip both produce.
  scope :with_difficulty, ->(value) { value.present? ? where(difficulty: value) : all }
  scope :with_topic, ->(value) { value.present? ? where(topic: value) : all }

  # Topics are free text rather than an enum, so the filter's options come from
  # what has actually been authored.
  def self.topics
    distinct.order(:topic).pluck(:topic)
  end

  # Routes address an exercise by slug (param: :slug), so path helpers have to
  # hand back the slug rather than the id or exercise_path(exercise) would build
  # a URL that the slug lookup cannot find.
  def to_param
    slug
  end

  def published?
    published_at.present? && published_at <= Time.current
  end
end
