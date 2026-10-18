require "test_helper"

class MarkdownTest < ActiveSupport::TestCase
  def render(text)
    Markdown.render(text)
  end

  test "renders the constructs exercise bodies actually use" do
    assert_match "<h2>Heading</h2>", render("## Heading")
    assert_match "<strong>bold</strong>", render("**bold**")
    assert_match "<em>italic</em>", render("*italic*")
    assert_match "<code>inline</code>", render("`inline`")
    assert_match "<li>one</li>", render("- one\n- two")
    assert_match "<blockquote>", render("> quoted")
  end

  test "keeps the language on a fenced code block" do
    html = render("```ruby\nputs 1\n```")

    assert_match "<pre", html
    assert_match %r{lang="ruby"}, html
    assert_match "puts 1", html
  end

  test "renders tables" do
    html = render("| a | b |\n| - | - |\n| 1 | 2 |")

    assert_match "<table>", html
    assert_match "<th>a</th>", html
    assert_match "<td>1</td>", html
  end

  test "does not add heading anchors" do
    html = render("## Heading")

    assert_no_match %r{<a[^>]*class="anchor"}, html
    assert_no_match %r{id="heading"}, html
  end

  # Syntax highlighting is on by default and inlines a fixed dark theme on every
  # token, which ignores the reader's colour scheme.
  test "does not inline syntax highlighting styles" do
    html = render("```ruby\nputs 1\n```")

    assert_no_match %r{style="}, html
    assert_no_match "background-color", html
  end

  test "marks its output as safe, because it has been sanitized" do
    assert_predicate render("hi"), :html_safe?
  end

  # nil.to_s is US-ASCII, not UTF-8, and Commonmarker raises TypeError on
  # anything that is not UTF-8. body_md is NOT NULL so nil should never arrive,
  # but a renderer that raises on it would also raise on any other non-UTF-8
  # string reaching it.
  test "handles empty and nil input" do
    assert_equal "", render("").strip
    assert_equal "", render(nil).strip
  end

  test "survives a string that is not valid UTF-8" do
    assert_nothing_raised do
      render("bad \xC3\x28 bytes".dup.force_encoding(Encoding::BINARY))
    end
  end

  test "renders non-ASCII text intact" do
    assert_match "café — naïve", render("café — naïve")
  end

  # The two layers from docs/decisions/0003-markdown-rendering.md. Commonmarker
  # drops raw HTML on its own; the allowlist is the independent second layer.
  # Either alone would stop these, which is the point.
  test "strips a script tag" do
    html = render("<script>alert(1)</script>")

    assert_no_match "script", html
    assert_no_match "alert", html
  end

  test "strips an image with an inline event handler" do
    html = render("<img src=x onerror=alert(1)>")

    assert_no_match "onerror", html
    assert_no_match "<img", html
  end

  test "strips an iframe" do
    assert_no_match "iframe", render(%(<iframe src="https://evil.test"></iframe>))
  end

  test "neutralizes a javascript: link" do
    html = render("[click](javascript:alert(1))")

    assert_no_match "javascript:", html
    assert_match "click", html
  end

  test "drops a data: URI image" do
    html = render("![x](data:text/html;base64,PHNjcmlwdD4=)")

    assert_no_match "data:", html
    assert_no_match "<img", html
  end

  test "keeps an ordinary link" do
    html = render("[ok](https://example.com)")

    assert_match %r{<a href="https://example\.com">ok</a>}, html
  end

  test "strips a tag that is outside the allowlist" do
    # style is the dangerous one: it is not script, so it survives naive
    # filters, and it can be used to cover the page.
    assert_no_match "style", render("<style>body{display:none}</style>")
  end

  test "strips attributes that are outside the allowlist" do
    html = render(%(<a href="https://example.com" onclick="alert(1)" class="x">ok</a>))

    assert_no_match "onclick", html
    assert_no_match "class=", html
  end

  test "every allowlisted tag survives a round trip" do
    # Guards against the allowlist and the renderer drifting apart: a tag listed
    # as allowed but no longer produced, or vice versa.
    html = render(<<~MARKDOWN)
      # h1
      ## h2

      paragraph with **strong**, *em*, ~~del~~ and `code`.

      - list

      1. ordered

      > quote

      ```
      pre
      ```

      | th |
      | -- |
      | td |

      [link](https://example.com)

      ---
    MARKDOWN

    %w[h1 h2 p strong em del code pre ul ol li blockquote a table thead tbody tr th td hr].each do |tag|
      assert_match(/<#{tag}[ >]/, html, "expected an allowlisted <#{tag}> to survive")
    end
  end
end
