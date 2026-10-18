require "application_system_test_case"

# The click path from the library to an exercise, which is the one thing the
# request tests cannot see: whether Turbo swaps a frame or navigates the page.
#
# This file exists because that distinction broke in real use and no test
# noticed. The request tests asserted the href, and the timer system test
# visited the exercise page directly, so nothing ever clicked a card.
class LibraryNavigationTest < ApplicationSystemTestCase
  setup do
    @exercise = exercises(:rename_a_method)
  end

  test "clicking a card opens the exercise rather than reporting content missing" do
    visit root_path
    click_on @exercise.title

    assert_selector "h1", text: @exercise.title
    assert_selector ".prose"
    assert_selector "[data-controller='timer']"
    assert_no_text "Content missing"
    assert_current_path exercise_path(@exercise)
  end

  test "the exercise page links back to the library" do
    visit exercise_path(@exercise)
    click_on "← All exercises"

    assert_current_path root_path
    assert_selector ".card"
  end

  test "filtering stays in the frame and does not reload the page" do
    visit root_path

    # A full page load would wipe this; a frame swap leaves it alone.
    page.execute_script("window.__probe = 'alive'")
    click_on "hard"

    assert_selector ".card", count: Exercise.published.where(difficulty: "hard").count
    assert_equal "alive", page.evaluate_script("window.__probe"),
      "filtering should swap the frame, not reload the page"
  end

  test "a filter survives a reload, and a card clicked from a filtered list still opens" do
    visit root_path
    click_on "easy"
    assert_current_path(/difficulty=easy/)

    visit current_url
    assert_selector ".chip--on", text: "easy"

    click_on @exercise.title
    assert_selector "h1", text: @exercise.title
    assert_no_text "Content missing"
  end

  test "the empty state returns to the whole library without leaving the frame" do
    visit root_path(difficulty: "easy", topic: "concurrency")
    assert_text "No exercises match"

    page.execute_script("window.__probe = 'alive'")
    click_on "Show everything"

    assert_selector ".card"
    assert_equal "alive", page.evaluate_script("window.__probe"),
      "clearing filters should swap the frame, not reload the page"
  end
end
