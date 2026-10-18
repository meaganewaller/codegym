require "test_helper"

class ExercisePageTest < ActionDispatch::IntegrationTest
  setup do
    @exercise = exercises(:rename_a_method)
    @scheduled = exercises(:scheduled_for_next_week)
    @draft = exercises(:never_published)
  end

  test "shows a published exercise" do
    get exercise_path(@exercise)

    assert_response :success
    assert_select "h1", @exercise.title
    assert_select ".exercise__summary", @exercise.summary
  end

  test "is addressed by slug, not id" do
    assert_equal "/exercises/#{@exercise.slug}", exercise_path(@exercise)
  end

  test "shows the difficulty, topic and minutes" do
    get exercise_path(@exercise)

    assert_select ".tag", text: @exercise.difficulty
    assert_select ".tag", text: @exercise.topic
    assert_select ".tag", text: "#{@exercise.minutes} min"
  end

  test "renders the body as HTML rather than printing the Markdown" do
    @exercise.update!(body_md: "## A heading\n\nA paragraph with `code`.")

    get exercise_path(@exercise)

    assert_select ".prose h2", "A heading"
    assert_select ".prose code", "code"
    assert_no_match "## A heading", response.body
  end

  test "the rendered body is sanitized on the page, not only in the renderer" do
    @exercise.update!(body_md: "Hello\n\n<script>alert(1)</script>")

    get exercise_path(@exercise)

    assert_response :success
    assert_select ".prose", text: /Hello/
    assert_no_match "<script>alert", response.body
  end

  test "links back to the library" do
    get exercise_path(@exercise)

    assert_select ".crumbs a[href=?]", root_path
  end

  # codegym-wwd: a future published_at means hidden, and the page must 404
  # rather than redirect. A redirect would confirm the slug exists.
  test "a scheduled exercise 404s" do
    get exercise_path(@scheduled)

    assert_response :not_found
  end

  test "an exercise with no published_at 404s" do
    get exercise_path(@draft)

    assert_response :not_found
  end

  test "an unknown slug 404s" do
    get "/exercises/no-such-exercise"

    assert_response :not_found
  end

  test "a hidden exercise 404s rather than redirecting" do
    get exercise_path(@scheduled)

    assert_response :not_found
    assert_not_equal 302, response.status
    assert_nil response.headers["Location"]
  end

  test "a hidden exercise leaks nothing about itself" do
    get exercise_path(@scheduled)

    assert_no_match @scheduled.title, response.body
    assert_no_match @scheduled.summary, response.body
  end

  # The timer. Its behavior lives in a Stimulus controller and is covered by the
  # system test; these assert the page hands it what it needs.
  test "mounts the timer with the slug and the minute budget" do
    get exercise_path(@exercise)

    assert_select "[data-controller=timer]" do
      assert_select "[data-timer-slug-value=?]", @exercise.slug
      assert_select "[data-timer-minutes-value=?]", @exercise.minutes.to_s
    end
  end

  test "the timer is keyed by slug so two exercises do not share one clock" do
    get exercise_path(@exercise)
    first = css_select("[data-timer-slug-value]").first["data-timer-slug-value"]

    get exercise_path(exercises(:read_a_stack_trace))
    second = css_select("[data-timer-slug-value]").first["data-timer-slug-value"]

    assert_not_equal first, second
  end

  test "the timer offers start and reset" do
    get exercise_path(@exercise)

    assert_select "[data-action=?]", "timer#toggle"
    assert_select "[data-action=?]", "timer#reset"
  end

  # Criterion: screen readers are told about phase changes, not every second.
  test "the only live region is the phase announcer, not the clock" do
    get exercise_path(@exercise)

    assert_select ".timer__clock:not([aria-live])"
    assert_select ".timer__clock[role=status]", count: 0
    assert_select "[data-timer-target=announcer][role=status]"
  end

  test "the announcer starts empty so nothing is announced on load" do
    get exercise_path(@exercise)

    assert_select "[data-timer-target=announcer]", text: ""
  end

  test "the timer is labelled for assistive technology" do
    get exercise_path(@exercise)

    assert_select ".timer[aria-label=?]", "Exercise timer"
  end

  test "library cards link to the exercise page" do
    get root_path

    assert_select ".card__title a[href=?]", exercise_path(@exercise), text: @exercise.title
  end

  # Regression: the card link sits inside the library turbo frame. Without
  # _top, Turbo loads the exercise page into that frame, finds no matching
  # turbo-frame#library in the response, and renders "Content missing" instead
  # of the exercise.
  test "a card link breaks out of the library frame" do
    get root_path

    assert_select ".card__title a[data-turbo-frame=?]", "_top"
  end

  # The other side of the same coin: filter links must NOT break out, or
  # filtering becomes a full page load.
  test "filter chips stay inside the frame" do
    get root_path

    assert_select ".filters .chip[data-turbo-frame]", count: 0
  end

  test "the show page has no library frame, which is why the link needs _top" do
    get exercise_path(@exercise)

    assert_select "turbo-frame#library", count: 0
  end
end
