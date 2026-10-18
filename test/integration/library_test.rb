require "test_helper"

class LibraryTest < ActionDispatch::IntegrationTest
  # The fixtures carry all four publication states, so these cover the published
  # scope through the page rather than only through the model.
  setup do
    @published = exercises(:rename_a_method)
    @also_published = exercises(:read_a_stack_trace)
    @scheduled = exercises(:scheduled_for_next_week)
    @draft = exercises(:never_published)
  end

  def card_titles
    css_select(".card .card__title").map { |node| node.text.strip }
  end

  test "the library is the home page" do
    get root_path

    assert_response :success
    assert_select "h1", "codegym"
  end

  test "lists published exercises with their difficulty, topic and minutes" do
    get root_path

    assert_includes card_titles, @published.title
    assert_select ".card", text: /#{Regexp.escape(@published.summary)}/
    assert_select ".tag", text: @published.difficulty
    assert_select ".tag", text: @published.topic
    assert_select ".tag", text: "#{@published.minutes} min"
  end

  # The guarantee codegym-wwd exists for, checked at the page rather than the
  # scope: a scheduled exercise is in the database and must not be on the page.
  test "a future published_at is absent from the library" do
    get root_path

    assert_not_includes card_titles, @scheduled.title
    assert_not_includes response.body, @scheduled.summary
  end

  test "an exercise with no published_at is absent from the library" do
    get root_path

    assert_not_includes card_titles, @draft.title
  end

  test "newest first" do
    get root_path

    titles = card_titles
    assert_operator titles.index(@also_published.title), :<,
      titles.index(@published.title),
      "expected the more recently published exercise first"
  end

  # Criterion: filters survive a refresh via the URL. A plain GET with the param
  # IS the refresh, so these also cover bookmarking and the back button.
  test "filters by difficulty from the query string" do
    get root_path(difficulty: "medium")

    assert_response :success
    assert_includes card_titles, @also_published.title
    assert_not_includes card_titles, @published.title
  end

  test "filters by topic from the query string" do
    get root_path(topic: @published.topic)

    assert_includes card_titles, @published.title
    assert_not_includes card_titles, @also_published.title
  end

  test "combines the two filters" do
    get root_path(difficulty: @published.difficulty, topic: @published.topic)

    assert_includes card_titles, @published.title
    assert_not_includes card_titles, @also_published.title
  end

  test "a filter never reaches past the published scope" do
    get root_path(difficulty: @scheduled.difficulty, topic: @scheduled.topic)

    assert_not_includes card_titles, @scheduled.title
  end

  # A hand-edited query string should show the empty state, not a 500.
  test "an unknown difficulty renders the empty state" do
    get root_path(difficulty: "impossible")

    assert_response :success
    assert_select ".card", false
    assert_select ".empty", text: /No exercises match/
  end

  test "an unknown topic renders the empty state" do
    get root_path(topic: "underwater-basket-weaving")

    assert_response :success
    assert_select ".empty", text: /No exercises match/
  end

  test "the empty state offers a way back to the whole library" do
    get root_path(difficulty: "impossible")

    assert_select ".empty a[href=?]", root_path, text: "Show everything"
  end

  test "an empty library reads differently from an over-filtered one" do
    Exercise.update_all(published_at: 1.week.from_now)

    get root_path

    assert_select ".empty", text: /No exercises are published yet/
    assert_select ".empty", text: /No exercises match/, count: 0
  end

  # Criterion: filtering does not reload the page. The frame plus
  # data-turbo-action="advance" is the mechanism for both halves -- Turbo swaps
  # only the frame, and advance pushes the URL so a refresh still works.
  test "the library sits in a turbo frame that advances the URL" do
    get root_path

    assert_select "turbo-frame#library[data-turbo-action=?]", "advance"
  end

  test "the filters are inside the frame so they re-render with the list" do
    get root_path

    assert_select "turbo-frame#library .filters .chip"
  end

  test "a turbo frame request returns the frame" do
    get root_path(difficulty: "medium"), headers: { "Turbo-Frame" => "library" }

    assert_response :success
    assert_select "turbo-frame#library"
    assert_includes card_titles, @also_published.title
  end

  test "the active chip is marked for assistive technology as well as visually" do
    get root_path(difficulty: "medium")

    assert_select ".chip.chip--on[aria-current=?]", "true", text: "medium"
  end

  test "each filter link keeps the other filter" do
    get root_path(difficulty: "medium", topic: "debugging")

    # The topic chips must carry the difficulty along, or clicking one silently
    # drops the other filter.
    assert_select ".chip[href=?]", root_path(difficulty: "medium", topic: "refactoring")
    # ...and the difficulty chips must carry the topic.
    assert_select ".chip[href=?]", root_path(difficulty: "easy", topic: "debugging")
  end

  test "the All chips clear only their own dimension" do
    get root_path(difficulty: "medium", topic: "debugging")

    assert_select ".chip[href=?]", root_path(topic: "debugging")
    assert_select ".chip[href=?]", root_path(difficulty: "medium")
  end

  test "topic filters are offered only for published exercises" do
    get root_path

    assert_select ".filters", text: /#{Regexp.escape(@published.topic)}/
    assert_select ".filters", text: /#{Regexp.escape(@scheduled.topic)}/, count: 0
  end

  # Signed-out is the only state until codegym-ir5. The badges it will bring are
  # the other half of this bead.
  test "a signed-out visitor sees the library and a prompt to sign in" do
    get root_path

    assert_select ".sign-in-prompt"
    assert_select ".card"
  end
end
