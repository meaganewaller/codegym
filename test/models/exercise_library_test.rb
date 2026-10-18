require "test_helper"

# Checks the real db/exercises/ directory rather than a temporary one. bin/ci
# already runs db:seed:replant, which would fail on a malformed file, but these
# assertions say *what* is wrong instead of just failing to seed, and they cover
# invariants seeding cannot see at all -- notably that no coach material has
# found its way into a user-facing file.
#
# Deliberately no assertion on the exact number of exercises: adding one should
# not be a failing test.
class ExerciseLibraryTest < ActiveSupport::TestCase
  COACH_HEADINGS = /Reference approach|Hint ladder|Common mistakes|What to notice/

  def directory
    ExerciseLoader.default_directory
  end

  def exercise_files
    Pathname.glob(directory.join("*.md")).reject { |p| p.to_s.end_with?(".coach.md") }.sort
  end

  def coach_files
    Pathname.glob(directory.join("*.coach.md")).sort
  end

  test "every authored exercise loads" do
    assert_not_empty exercise_files, "expected authored exercises in #{directory}"

    result = ExerciseLoader.load_all
    assert_equal exercise_files.count, result.total
  end

  test "loading the real library twice changes nothing the second time" do
    ExerciseLoader.load_all
    second = ExerciseLoader.load_all

    assert_equal 0, second.created
    assert_equal 0, second.updated
    assert_equal exercise_files.count, second.unchanged
  end

  test "every exercise has coach notes and every coach file has an exercise" do
    authored = exercise_files.map { |path| path.basename(".md").to_s }
    coached = coach_files.map { |path| path.basename.to_s.delete_suffix(".coach.md") }

    assert_equal [], authored - coached,
      "these exercises have no coach notes"
    assert_equal [], coached - authored,
      "these coach files have no exercise beside them"
  end

  # The guardrail from CLAUDE.md: the coach must not leak solutions. The hint
  # ladder is worthless if the answer is already on the page.
  test "no coach material appears in a user-facing exercise file" do
    offenders = exercise_files.select { |path| path.read.match?(COACH_HEADINGS) }

    assert_equal [], offenders.map { |path| path.basename.to_s },
      "coach headings found in user-facing files"
  end

  test "no coach material reaches body_md in the database" do
    ExerciseLoader.load_all
    offenders = Exercise.where(slug: exercise_files.map { |p| p.basename(".md").to_s })
      .select { |exercise| exercise.body_md.match?(COACH_HEADINGS) }

    assert_equal [], offenders.map(&:slug), "coach material loaded into body_md"
  end

  test "no coach file is ever loaded as an exercise" do
    ExerciseLoader.load_all
    coached = coach_files.map { |path| path.basename.to_s.delete_suffix(".coach.md") }

    # A coach file loaded by mistake would arrive under its exercise's slug, so
    # the check is on the body rather than on the presence of the slug.
    offenders = coached.filter_map do |slug|
      exercise = Exercise.find_by(slug: slug)
      slug if exercise&.body_md&.match?(COACH_HEADINGS)
    end

    assert_equal [], offenders, "these look like they were loaded from a coach file"
  end

  test "every exercise file has the sections the house format requires" do
    missing = exercise_files.filter_map do |path|
      contents = path.read
      absent = [ "## The problem", "## Before you code", "## Stretch" ]
        .reject { |heading| contents.include?(heading) }
      [ path.basename.to_s, absent ] if absent.any?
    end

    assert_equal [], missing
  end

  test "every coach file has the sections the house format requires" do
    missing = coach_files.filter_map do |path|
      contents = path.read
      absent = [ "## Reference approach", "## Edge cases", "## Common mistakes",
                 "## Hint ladder", "## What to notice" ]
        .reject { |heading| contents.include?(heading) }
      [ path.basename.to_s, absent ] if absent.any?
    end

    assert_equal [], missing
  end

  # Four rungs, going from a question to a sketch. A ladder with one rung is a
  # spoiler with extra steps.
  test "every hint ladder has four rungs" do
    wrong = coach_files.filter_map do |path|
      ladder = path.read[/## Hint ladder\n(.*?)\n## /m, 1]
      rungs = ladder.to_s.scan(/^\d\. /).count
      [ path.basename.to_s, rungs ] if rungs != 4
    end

    assert_equal [], wrong
  end

  test "loaded exercises use the difficulties and minutes the house format allows" do
    ExerciseLoader.load_all

    Exercise.where(slug: exercise_files.map { |p| p.basename(".md").to_s }).each do |exercise|
      assert_includes Exercise::DIFFICULTIES, exercise.difficulty, exercise.slug
      assert_includes 1..600, exercise.minutes, exercise.slug
    end
  end
end
