require "test_helper"

class AttemptTest < ActiveSupport::TestCase
  def valid_attributes(**overrides)
    {
      user: users(:meagan), exercise: exercises(:never_published),
      outcome: "solved", minutes: 20
    }.merge(overrides)
  end

  def row(**overrides)
    {
      user_id: users(:meagan).id, exercise_id: exercises(:never_published).id,
      outcome: "solved", minutes: 20,
      created_at: Time.current, updated_at: Time.current
    }.merge(overrides)
  end

  test "the fixtures are valid" do
    assert_predicate attempts(:solved_quickly), :valid?
  end

  test "is valid with only a user, exercise, outcome and minutes" do
    assert_predicate Attempt.new(valid_attributes), :valid?
  end

  test "plan, stuck_on and learned are optional" do
    attempt = Attempt.new(valid_attributes)

    assert_predicate attempt, :valid?
    assert_nil attempt.plan
    assert_nil attempt.stuck_on
    assert_nil attempt.learned
  end

  test "requires a user and an exercise" do
    attempt = Attempt.new(outcome: "solved", minutes: 10)

    assert_not_predicate attempt, :valid?
    assert_includes attempt.errors[:user], "must exist"
    assert_includes attempt.errors[:exercise], "must exist"
  end

  test "accepts each known outcome" do
    Attempt::OUTCOMES.each do |outcome|
      attempt = Attempt.new(valid_attributes(outcome: outcome))

      assert_predicate attempt, :valid?, "expected #{outcome} to be accepted"
    end
  end

  test "rejects an unknown outcome as a validation error, not an exception" do
    attempt = Attempt.new(valid_attributes(outcome: "gave-up"))

    assert_not_predicate attempt, :valid?
    assert_includes attempt.errors[:outcome], "is not included in the list"
  end

  test "accepts the minutes boundaries and rejects what is outside them" do
    [ 0, 600 ].each do |minutes|
      assert_predicate Attempt.new(valid_attributes(minutes: minutes)), :valid?,
        "expected #{minutes} minutes to be accepted"
    end

    [ -1, 601 ].each do |minutes|
      attempt = Attempt.new(valid_attributes(minutes: minutes))

      assert_not_predicate attempt, :valid?, "expected #{minutes} to be rejected"
      assert_not_empty attempt.errors[:minutes]
    end
  end

  # The append-only rule: a retry is a new row, never an edit of the old one, so
  # nothing may stop a user attempting the same exercise twice.
  test "a user can attempt the same exercise more than once" do
    exercise = exercises(:rename_a_method)
    user = users(:meagan)

    assert_not_empty user.attempts.where(exercise: exercise)

    retry_attempt = Attempt.new(
      valid_attributes(user: user, exercise: exercise, outcome: "partial")
    )

    assert_predicate retry_attempt, :valid?
    assert_difference -> { user.attempts.count }, 1 do
      retry_attempt.save!
    end
  end

  test "exercises through attempts are distinct even after a retry" do
    user = users(:meagan)
    exercise = exercises(:rename_a_method)
    Attempt.create!(valid_attributes(user: user, exercise: exercise, outcome: "solved"))

    assert_equal user.exercises.count, user.exercises.uniq.count
    assert_includes user.exercises, exercise
  end

  # Database-level checks. See the note in UserTest on why insert_all! and not
  # insert_all.
  test "the database rejects an unknown outcome" do
    assert_raises ActiveRecord::StatementInvalid do
      Attempt.insert_all!([ row(outcome: "gave-up") ])
    end
  end

  test "the database rejects minutes outside the range" do
    [ -1, 601 ].each do |minutes|
      assert_raises ActiveRecord::StatementInvalid, "expected #{minutes} to be refused" do
        Attempt.insert_all!([ row(minutes: minutes) ])
      end
    end
  end

  test "the database rejects a null in any required column" do
    [ :user_id, :exercise_id, :outcome, :minutes ].each do |column|
      assert_raises ActiveRecord::NotNullViolation, "expected #{column} to be NOT NULL" do
        Attempt.insert_all!([ row(column => nil) ])
      end
    end
  end

  test "the database rejects an attempt pointing at a user who does not exist" do
    assert_raises ActiveRecord::InvalidForeignKey do
      Attempt.insert_all!([ row(user_id: 999_999) ])
    end
  end

  test "the database rejects an attempt pointing at an exercise that does not exist" do
    assert_raises ActiveRecord::InvalidForeignKey do
      Attempt.insert_all!([ row(exercise_id: 999_999) ])
    end
  end

  # The progress page reads a user's attempts in time order and the library shows
  # per-exercise status, so both composite indexes are a stated requirement and
  # not an incidental detail of the migration.
  test "the indexes the progress and library pages rely on exist" do
    columns = Attempt.connection.indexes(:attempts).map(&:columns)

    assert_includes columns, [ "user_id", "created_at" ]
    assert_includes columns, [ "user_id", "exercise_id" ]
  end

  test "the database refuses to delete an exercise that has attempts" do
    # delete, not destroy: this leaves the restriction to the foreign key rather
    # than to dependent: :restrict_with_error.
    assert_raises ActiveRecord::InvalidForeignKey do
      exercises(:rename_a_method).delete
    end
  end
end
