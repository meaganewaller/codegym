class Attempt < ApplicationRecord
  OUTCOMES = %w[solved partial stuck].freeze

  belongs_to :user
  belongs_to :exercise

  # See the notes in Exercise: mapped value-to-itself because the column is a
  # string, and validated rather than raising on an unknown value.
  enum :outcome, OUTCOMES.index_by(&:itself), validate: true

  validates :minutes, numericality: {
    only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 600
  }
end
