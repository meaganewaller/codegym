require "test_helper"

# The second half of codegym-33z: what the library says about what you have
# already done. The criterion is that it reflects the signed-in user's attempts
# and nobody else's.
class LibraryStatusTest < ActionDispatch::IntegrationTest
  setup do
    @me = users(:meagan)
    @someone_else = users(:visitor)
    @solved = exercises(:rename_a_method)     # meagan solved this in fixtures
    @stuck = exercises(:read_a_stack_trace)   # meagan got stuck on this
    @untouched = exercises(:never_published)
  end

  def status_for(exercise)
    card = css_select(".card").find { |node| node.text.include?(exercise.title) }
    card&.css(".tag--solved, .tag--tried")&.map { |tag| tag.text.strip }
  end

  test "a signed-out visitor sees no status at all" do
    get root_path

    assert_select ".card"
    assert_select ".tag--solved", count: 0
    assert_select ".tag--tried", count: 0
  end

  test "a solved exercise is marked solved" do
    sign_in_as @me
    get root_path

    assert_equal [ "Solved" ], status_for(@solved)
  end

  test "an attempted but unsolved exercise shows the number of tries" do
    sign_in_as @me
    get root_path

    assert_equal [ "Tried 1 time" ], status_for(@stuck)
  end

  test "the try count is pluralized" do
    @stuck.attempts.create!(user: @me, outcome: "stuck", minutes: 10)
    sign_in_as @me
    get root_path

    assert_equal [ "Tried 2 times" ], status_for(@stuck)
  end

  test "an exercise you have never attempted shows nothing" do
    published = @untouched.tap { |e| e.update!(published_at: 1.day.ago) }
    sign_in_as @me
    get root_path

    assert_equal [], status_for(published)
  end

  # Solved is the answer to "have I done this". The number of tries only
  # matters while the answer is still no.
  test "solved wins over the attempt count" do
    @solved.attempts.create!(user: @me, outcome: "stuck", minutes: 5)
    sign_in_as @me
    get root_path

    assert_equal [ "Solved" ], status_for(@solved)
  end

  test "a retry after solving still reads as solved" do
    @solved.attempts.create!(user: @me, outcome: "partial", minutes: 5)
    sign_in_as @me
    get root_path

    assert_equal [ "Solved" ], status_for(@solved)
  end

  # The acceptance criterion, and the one that matters: someone else's history
  # must not show up as yours.
  test "another user's attempts are not shown as yours" do
    assert_not_empty @me.attempts, "fixture precondition: meagan has attempts"
    assert_empty @someone_else.attempts, "fixture precondition: visitor has none"

    sign_in_as @someone_else
    get root_path

    assert_select ".tag--solved", count: 0
    assert_select ".tag--tried", count: 0
  end

  test "each user sees their own status for the same exercise" do
    @solved.attempts.create!(user: @someone_else, outcome: "stuck", minutes: 7)

    sign_in_as @me
    get root_path
    assert_equal [ "Solved" ], status_for(@solved)

    reset!

    sign_in_as @someone_else
    get root_path
    assert_equal [ "Tried 1 time" ], status_for(@solved)
  end

  test "status disappears again after signing out" do
    sign_in_as @me
    get root_path
    assert_select ".tag--solved"

    delete session_path
    get root_path

    assert_select ".tag--solved", count: 0
  end

  test "status survives filtering" do
    sign_in_as @me
    get root_path(difficulty: @solved.difficulty)

    assert_equal [ "Solved" ], status_for(@solved)
  end

  # The whole point of AttemptSummary: a dozen cards must not be a dozen
  # queries. Two grouped lookups cover the page however long it gets.
  test "status costs the same number of queries however many exercises there are" do
    sign_in_as @me

    baseline = count_queries { get root_path }

    5.times do |i|
      exercise = Exercise.create!(
        slug: "extra-#{i}", title: "Extra #{i}", summary: "s", body_md: "b",
        difficulty: "easy", topic: "algorithms", minutes: 10, published_at: 1.day.ago
      )
      exercise.attempts.create!(user: @me, outcome: "solved", minutes: 5)
    end

    assert_equal baseline, count_queries { get root_path },
      "adding exercises changed the query count, which means a query per card"
  end

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end
