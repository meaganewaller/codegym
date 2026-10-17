require "test_helper"

class ExerciseTest < ActiveSupport::TestCase
  # Every required column, so a constraint test can change one field and leave
  # the rest valid.
  def valid_attributes(**overrides)
    {
      slug: "a-new-exercise", title: "A new exercise", summary: "Summary.",
      body_md: "Body.", difficulty: "easy", topic: "refactoring", minutes: 25
    }.merge(overrides)
  end

  def row(**overrides)
    valid_attributes(**overrides)
      .merge(created_at: Time.current, updated_at: Time.current)
  end

  test "the fixtures are valid" do
    assert_predicate exercises(:rename_a_method), :valid?
  end

  test "is valid with every required field" do
    assert_predicate Exercise.new(valid_attributes), :valid?
  end

  test "requires slug, title, summary, body_md and topic" do
    exercise = Exercise.new(difficulty: "easy", minutes: 10)

    assert_not_predicate exercise, :valid?
    [ :slug, :title, :summary, :body_md, :topic ].each do |field|
      assert_includes exercise.errors[field], "can't be blank",
        "expected #{field} to be required"
    end
  end

  test "rejects a duplicate slug" do
    duplicate = Exercise.new(valid_attributes(slug: exercises(:rename_a_method).slug))

    assert_not_predicate duplicate, :valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "accepts each known difficulty" do
    Exercise::DIFFICULTIES.each do |difficulty|
      exercise = Exercise.new(valid_attributes(difficulty: difficulty))

      assert_predicate exercise, :valid?, "expected #{difficulty} to be accepted"
    end
  end

  test "rejects an unknown difficulty as a validation error, not an exception" do
    exercise = Exercise.new(valid_attributes(difficulty: "impossible"))

    assert_not_predicate exercise, :valid?
    assert_includes exercise.errors[:difficulty], "is not included in the list"
  end

  test "accepts the minutes boundaries and rejects what is outside them" do
    [ 0, 600 ].each do |minutes|
      assert_predicate Exercise.new(valid_attributes(minutes: minutes)), :valid?,
        "expected #{minutes} minutes to be accepted"
    end

    [ -1, 601 ].each do |minutes|
      exercise = Exercise.new(valid_attributes(minutes: minutes))

      assert_not_predicate exercise, :valid?, "expected #{minutes} to be rejected"
      assert_not_empty exercise.errors[:minutes]
    end
  end

  test "requires minutes to be a whole number" do
    exercise = Exercise.new(valid_attributes(minutes: 12.5))

    assert_not_predicate exercise, :valid?
    assert_includes exercise.errors[:minutes], "must be an integer"
  end

  # Publication. Null and future both mean hidden; only these two states and
  # "published" exist, and scheduled publishing depends on it.
  test "published scope includes only exercises whose date has arrived" do
    published = Exercise.published

    assert_includes published, exercises(:rename_a_method)
    assert_includes published, exercises(:read_a_stack_trace)
    assert_not_includes published, exercises(:scheduled_for_next_week)
    assert_not_includes published, exercises(:never_published)
  end

  test "published? agrees with the scope for every publication state" do
    assert_predicate exercises(:rename_a_method), :published?
    assert_not_predicate exercises(:scheduled_for_next_week), :published?
    assert_not_predicate exercises(:never_published), :published?
  end

  test "an exercise published exactly now counts as published" do
    exercise = Exercise.create!(valid_attributes(published_at: Time.current))

    assert_predicate exercise, :published?
    assert_includes Exercise.published, exercise
  end

  test "refuses to delete an exercise that someone has attempted" do
    exercise = exercises(:rename_a_method)

    assert_not_empty exercise.attempts
    assert_no_difference -> { Exercise.count } do
      assert_not exercise.destroy
    end
    assert_includes exercise.errors[:base],
      "Cannot delete record because dependent attempts exist"
  end

  # Database-level checks: insert_all! bypasses the model entirely, so these
  # prove the constraints are in the schema. See the note in UserTest on why the
  # bang form matters.
  test "the database rejects an unknown difficulty" do
    assert_raises ActiveRecord::StatementInvalid do
      Exercise.insert_all!([ row(difficulty: "impossible") ])
    end
  end

  test "the database rejects minutes outside the range" do
    [ -1, 601 ].each do |minutes|
      assert_raises ActiveRecord::StatementInvalid, "expected #{minutes} to be refused" do
        Exercise.insert_all!([ row(slug: "slug-#{minutes}", minutes: minutes) ])
      end
    end
  end

  test "the database rejects a duplicate slug" do
    assert_raises ActiveRecord::RecordNotUnique do
      Exercise.insert_all!([ row(slug: exercises(:rename_a_method).slug) ])
    end
  end

  test "the database rejects a null in any required column" do
    [ :slug, :title, :summary, :body_md, :difficulty, :topic, :minutes ].each do |column|
      assert_raises ActiveRecord::NotNullViolation, "expected #{column} to be NOT NULL" do
        Exercise.insert_all!([ row(slug: "slug-for-#{column}", column => nil) ])
      end
    end
  end
end
