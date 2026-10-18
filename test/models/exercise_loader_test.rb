require "test_helper"
require "tmpdir"

class ExerciseLoaderTest < ActiveSupport::TestCase
  # Malformed files are written per-test rather than committed as fixtures, so
  # each failure case sits next to the message it is expected to produce.
  def setup
    @directory = Pathname.new(Dir.mktmpdir("exercises"))
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def write(name, contents)
    @directory.join(name).write(contents)
  end

  def write_exercise(slug, body: "## The problem\n\nDo the thing.", **overrides)
    front_matter = {
      "slug" => slug, "title" => "Merge intervals", "summary" => "One sentence.",
      "difficulty" => "easy", "topic" => "algorithms", "minutes" => 30
    }.merge(overrides.transform_keys(&:to_s))

    yaml = front_matter.map { |key, value| "#{key}: #{value}" }.join("\n")
    write("#{slug}.md", "---\n#{yaml}\n---\n\n#{body}\n")
  end

  def load_all
    ExerciseLoader.load_all(directory: @directory)
  end

  test "loads an exercise, mapping front matter onto columns and the body onto body_md" do
    write_exercise("merge-intervals", body: "## The problem\n\nMerge them.")
    result = load_all

    assert_equal 1, result.created
    exercise = Exercise.find_by!(slug: "merge-intervals")
    assert_equal "Merge intervals", exercise.title
    assert_equal "One sentence.", exercise.summary
    assert_equal "easy", exercise.difficulty
    assert_equal "algorithms", exercise.topic
    assert_equal 30, exercise.minutes
    assert_equal "## The problem\n\nMerge them.", exercise.body_md
    assert_nil exercise.published_at
  end

  # The acceptance criterion for codegym-lak: a second run changes nothing.
  test "running twice creates nothing the second time and leaves updated_at alone" do
    write_exercise("merge-intervals")

    assert_difference -> { Exercise.count }, 1 do
      assert_equal 1, load_all.created
    end

    exercise = Exercise.find_by!(slug: "merge-intervals")
    before = exercise.updated_at

    assert_no_difference -> { Exercise.count } do
      second = load_all
      assert_equal 0, second.created
      assert_equal 0, second.updated
      assert_equal 1, second.unchanged
    end

    assert_equal before, exercise.reload.updated_at
  end

  test "updates an exercise in place when its file changes, keyed on slug" do
    write_exercise("merge-intervals")
    load_all
    original = Exercise.find_by!(slug: "merge-intervals")

    write_exercise("merge-intervals", title: "Merge intervals, carefully", minutes: 45)

    assert_no_difference -> { Exercise.count } do
      assert_equal 1, load_all.updated
    end

    original.reload
    assert_equal "Merge intervals, carefully", original.title
    assert_equal 45, original.minutes
  end

  # Nothing in the database may carry a solution, or the hint ladder is pointless.
  test "never loads a coach file, even when no exercise file sits beside it" do
    write("orphan-notes.coach.md", "---\nslug: orphan-notes\n---\n\n## Reference approach\n\nThe answer.")
    write_exercise("merge-intervals")

    result = load_all

    assert_equal 1, result.total
    assert_equal [ "merge-intervals" ], Exercise.where(slug: %w[merge-intervals orphan-notes]).pluck(:slug)
    assert_nil Exercise.find_by(slug: "orphan-notes")
  end

  test "ignores a coach file belonging to a loaded exercise" do
    write_exercise("merge-intervals")
    write("merge-intervals.coach.md", "## Reference approach\n\nSort by start, then fold.")

    assert_equal 1, load_all.total
    assert_not_includes Exercise.find_by!(slug: "merge-intervals").body_md, "Sort by start"
  end

  test "reads published_at as a UTC timestamp" do
    write_exercise("merge-intervals", published_at: "2026-11-02 09:30:00")
    load_all

    published_at = Exercise.find_by!(slug: "merge-intervals").published_at
    assert_equal Time.utc(2026, 11, 2, 9, 30, 0), published_at
  end

  test "a future published_at loads but stays out of the published scope" do
    write_exercise("merge-intervals", published_at: 1.week.from_now.utc.strftime("%Y-%m-%d %H:%M:%S"))
    load_all

    exercise = Exercise.find_by!(slug: "merge-intervals")
    assert_not_predicate exercise, :published?
    assert_not_includes Exercise.published, exercise
  end

  test "loads every exercise in the directory" do
    write_exercise("merge-intervals")
    write_exercise("trie-autocomplete", difficulty: "medium")
    write_exercise("lru-cache", difficulty: "hard")

    assert_equal 3, load_all.created
    assert_equal %w[lru-cache merge-intervals trie-autocomplete],
      Exercise.where(slug: %w[merge-intervals trie-autocomplete lru-cache]).order(:slug).pluck(:slug)
  end

  test "an empty directory is not an error" do
    assert_equal 0, load_all.total
  end

  # Failure cases. bin/ci runs db:seed:replant, so each of these breaks the build
  # rather than reaching production, and the message has to name the file.
  test "refuses a file with no front matter" do
    write("merge-intervals.md", "## The problem\n\nNo front matter here.")

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "merge-intervals.md", error.message
    assert_match "no YAML front matter", error.message
  end

  test "refuses a file whose front matter is missing a required key" do
    write("merge-intervals.md", "---\nslug: merge-intervals\ntitle: Merge intervals\n---\n\nBody.")

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "missing front matter", error.message
    assert_match "summary", error.message
  end

  # A typo like "minute:" would otherwise be dropped silently, leaving the column
  # it meant to set at its default.
  test "refuses an unknown front matter key rather than ignoring it" do
    write_exercise("merge-intervals", minute: 30)

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "unknown front matter", error.message
    assert_match "minute", error.message
  end

  test "refuses a slug that disagrees with the filename" do
    write_exercise("merge-intervals", slug: "something-else")

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "something-else", error.message
    assert_match "merge-intervals", error.message
  end

  test "refuses an empty body, since body_md is NOT NULL" do
    write("merge-intervals.md", <<~MARKDOWN)
      ---
      slug: merge-intervals
      title: Merge intervals
      summary: One sentence.
      difficulty: easy
      topic: algorithms
      minutes: 30
      ---

    MARKDOWN

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "body is empty", error.message
  end

  test "refuses a difficulty the model does not accept, naming the file" do
    write_exercise("merge-intervals", difficulty: "impossible")

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "merge-intervals.md", error.message
    assert_match "Difficulty", error.message
  end

  test "refuses minutes outside the permitted range" do
    write_exercise("merge-intervals", minutes: 900)

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "Minutes", error.message
  end

  test "refuses malformed YAML without leaking a Psych error to the caller" do
    write("merge-intervals.md", "---\nslug: merge-intervals\n  title: bad indent\n---\n\nBody.")

    error = assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end
    assert_match "merge-intervals.md", error.message
  end

  # All or nothing: the alphabetically earlier file is valid and would have been
  # saved already by the time the later one fails.
  test "writes nothing at all when any file in the directory is invalid" do
    write_exercise("aaa-valid")
    write_exercise("zzz-invalid", difficulty: "impossible")

    assert_no_difference -> { Exercise.count } do
      assert_raises ExerciseLoader::InvalidExercise do
        load_all
      end
    end

    assert_nil Exercise.find_by(slug: "aaa-valid")
  end

  test "an invalid file does not undo an exercise loaded by an earlier run" do
    write_exercise("aaa-valid")
    load_all
    write_exercise("zzz-invalid", difficulty: "impossible")

    assert_raises ExerciseLoader::InvalidExercise do
      load_all
    end

    assert_not_nil Exercise.find_by(slug: "aaa-valid")
  end
end
