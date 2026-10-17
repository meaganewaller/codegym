require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "the fixtures are valid" do
    assert_predicate users(:meagan), :valid?
  end

  test "requires a github_id" do
    user = User.new(login: "nobody")

    assert_not_predicate user, :valid?
    assert_includes user.errors[:github_id], "can't be blank"
  end

  test "requires a login" do
    user = User.new(github_id: 99)

    assert_not_predicate user, :valid?
    assert_includes user.errors[:login], "can't be blank"
  end

  test "rejects a duplicate github_id" do
    duplicate = User.new(github_id: users(:meagan).github_id, login: "imposter")

    assert_not_predicate duplicate, :valid?
    assert_includes duplicate.errors[:github_id], "has already been taken"
  end

  test "allows a duplicate login, because logins can change hands" do
    user = User.new(github_id: 555, login: users(:meagan).login)

    assert_predicate user, :valid?
  end

  # Database-level checks. Each one bypasses Active Record, so it proves the
  # constraint is in the schema and not only in the model. Timestamps are passed
  # explicitly so a missing created_at cannot make a test pass for the wrong
  # reason.
  #
  # insert_all! and not insert_all: the plain form passes on_duplicate: :skip,
  # so a unique violation is silently swallowed and the test would pass while
  # proving nothing. The bang form passes on_duplicate: :raise.
  test "the database rejects a duplicate github_id" do
    assert_raises ActiveRecord::RecordNotUnique do
      User.insert_all!([ {
        github_id: users(:meagan).github_id, login: "imposter",
        created_at: Time.current, updated_at: Time.current
      } ])
    end
  end

  test "the database rejects a null github_id" do
    assert_raises ActiveRecord::NotNullViolation do
      User.insert_all!([ {
        github_id: nil, login: "nobody",
        created_at: Time.current, updated_at: Time.current
      } ])
    end
  end

  test "the database rejects a null login" do
    assert_raises ActiveRecord::NotNullViolation do
      User.insert_all!([ {
        github_id: 4242, login: nil,
        created_at: Time.current, updated_at: Time.current
      } ])
    end
  end

  test "deleting a user takes their attempts with them" do
    user = users(:meagan)

    assert_not_empty user.attempts

    # delete, not destroy: this leaves the cascade to the database rather than
    # to dependent: :destroy.
    assert_difference -> { Attempt.count }, -user.attempts.count do
      user.delete
    end
  end
end
