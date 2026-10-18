# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  group "Checks", parallel: 2 do
    step "Style: Ruby", "bin/rubocop"
    step "Security: Gem audit", "bin/bundler-audit"
    step "Security: Importmap vulnerability audit", "bin/importmap audit"
    step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

    group "Tests" do
      step "Tests: Rails", "bin/rails test"
      step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

      # On, and worth the roughly 25 seconds it costs. The timer and the
      # library's frame navigation are only observable in a browser, and a
      # "Content missing" bug reached the owner precisely because bin/ci could
      # not see a click. A gate that skips the only coverage of a feature is
      # not a gate. Needs Chrome; the GitHub workflow runs the same step.
      step "Tests: System", "bin/rails test:system"
    end
  end

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
