require "application_system_test_case"

# The one system test the plan calls for. The timer's behavior lives in a
# Stimulus controller and in localStorage, so nothing below the browser can tell
# whether it survives a reload -- which is the acceptance criterion.
class TimerTest < ApplicationSystemTestCase
  setup do
    @exercise = exercises(:rename_a_method)
  end

  # Capybara keeps one browser session across tests, so localStorage would leak
  # a running timer from one test into the next. Storage is per origin, so the
  # page has to be open before it can be cleared.
  def open_exercise(exercise = @exercise, fresh: true)
    visit exercise_path(exercise)

    if fresh
      page.execute_script("window.localStorage.clear()")
      visit exercise_path(exercise)
    end
  end

  def toggle_button
    find("[data-timer-target='toggle']")
  end

  def seed_elapsed(minutes, running: false)
    page.execute_script(<<~JS)
      window.localStorage.setItem(
        "codegym.timer.#{@exercise.slug}",
        JSON.stringify({ startedAt: #{running ? "Date.now()" : "null"},
                         accumulated: #{(minutes * 60_000).to_i},
                         running: #{running} })
      )
    JS
    visit exercise_path(@exercise)
  end

  test "starts at zero in the plan phase" do
    open_exercise

    assert_selector ".timer__clock", text: "00:00"
    assert_selector ".timer[data-phase='plan']"
    assert_equal "Start", toggle_button.text
  end

  test "counts up once started" do
    open_exercise
    click_on "Start"

    assert_selector "[data-timer-target='toggle']", text: "Pause"
    assert_selector ".timer__clock", text: /00:0[1-9]/
  end

  # The acceptance criterion: reloading the page keeps the timer running.
  test "keeps running across a reload" do
    open_exercise
    click_on "Start"
    assert_selector ".timer__clock", text: /00:0[1-9]/

    visit exercise_path(@exercise)

    assert_selector "[data-timer-target='toggle']", text: "Pause"
    assert_no_selector ".timer__clock", text: "00:00"
  end

  test "pause holds the clock and resume continues from there" do
    open_exercise
    click_on "Start"
    assert_selector ".timer__clock", text: /00:0[1-9]/

    click_on "Pause"
    assert_selector "[data-timer-target='toggle']", text: "Resume"

    held = find(".timer__clock").text
    sleep 2
    assert_equal held, find(".timer__clock").text, "a paused clock should not move"

    click_on "Resume"
    assert_selector "[data-timer-target='toggle']", text: "Pause"
  end

  test "a paused timer is still paused after a reload" do
    open_exercise
    click_on "Start"
    assert_selector ".timer__clock", text: /00:0[1-9]/
    click_on "Pause"
    held = find(".timer__clock").text

    visit exercise_path(@exercise)

    assert_selector "[data-timer-target='toggle']", text: "Resume"
    assert_selector ".timer__clock", text: held
  end

  test "reset returns the timer to zero and forgets it" do
    open_exercise
    click_on "Start"
    assert_selector ".timer__clock", text: /00:0[1-9]/

    click_on "Reset"

    assert_selector ".timer__clock", text: "00:00"
    assert_selector ".timer[data-phase='plan']"
    assert_equal "Start", toggle_button.text

    visit exercise_path(@exercise)
    assert_selector ".timer__clock", text: "00:00"
  end

  # rename_a_method is 20 minutes: plan below 3:20, build to 16:40, reflect after.
  test "moves through plan, build and reflect as time is used" do
    open_exercise

    # Matched case-insensitively: the label is uppercased by CSS, and Capybara
    # reads rendered text, so text: "Plan" finds "PLAN" and fails.
    seed_elapsed(1)
    assert_selector ".timer[data-phase='plan']"
    assert_selector "[data-timer-target='phase']", text: /plan/i

    seed_elapsed(10)
    assert_selector ".timer[data-phase='build']"
    assert_selector "[data-timer-target='phase']", text: /build/i

    seed_elapsed(18)
    assert_selector ".timer[data-phase='reflect']"
    assert_selector "[data-timer-target='phase']", text: /reflect/i
  end

  test "stays in reflect past the budget rather than wrapping" do
    open_exercise
    seed_elapsed(45)

    assert_selector ".timer[data-phase='reflect']"
    assert_selector ".timer__clock", text: "45:00"
  end

  # Criterion: screen readers hear about phase changes, not every second.
  test "announces a phase change but says nothing on load" do
    open_exercise
    seed_elapsed(3.2, running: true)

    assert_selector ".timer[data-phase='plan']"
    assert_equal "", find("[data-timer-target='announcer']", visible: :all).text(:all).strip

    # 3:12 plus a few seconds crosses the 3:20 plan/build boundary.
    assert_selector ".timer[data-phase='build']", wait: 15
    assert_match(/Build phase/, find("[data-timer-target='announcer']", visible: :all).text(:all))
  end

  test "two exercises keep separate timers" do
    open_exercise
    click_on "Start"
    assert_selector ".timer__clock", text: /00:0[1-9]/

    visit exercise_path(exercises(:read_a_stack_trace))

    assert_selector ".timer__clock", text: "00:00"
    assert_selector "[data-timer-target='toggle']", text: "Start"
  end
end
