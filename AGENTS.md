# Code (a Runwell plugin): guide for AI agents

A Rails engine loaded into a Runwell install, key `coding` (README.md says what it does). Run it
from a Runwell checkout with `bin/rails "plugins:link[../runwell-coding]"`, `bin/rails db:migrate`,
and switch it on in Settings › Plugins. Read Runwell's `docs/plugin-contract.md` (use nothing of
the core's beyond it), its `AGENTS.md` (the conventions this code follows: ReActionView rules,
strict locals, `herb:key`, no inline CSS, `term()` for the core's nouns, no N+1) and
`docs/runeui-migration.md`.

Needs Runwell 6.0 or later (1.0.0; 0.2.0 was the last for Runwell 3.0 to 4.x). The core's nouns are
**Work** (`Work`, addressed by its `ref`, `Work:P-3`) and **Task** (`Task`); what comes in waits in
Intake (`task.intake?`); there is no home page.

## How it's built

- `Coding::Repository` (`coding_repositories`) is a git remote linked to a `Client`, `Work` or
  `Task` (a polymorphic `linkable`, with `work_id` and `client_id` kept beside it). `Repository.for`
  is the nearest level that has any: a task's own, else its work's, else its client's (one query).
  Linking a section links its work (`linkable_for`)
- `Coding::Branch` ties a task to a branch in a repository and its pull request (`pr_*`,
  `checks_state`). `Branch.name_for(task)` is `p-4/58-slug` (`task/58-slug` for a task straight on
  a client; before 1.0 that was `work/58-slug`, and `task_from` reads both). `Branch.record!` is
  how anyone reports one (the tools, the AI queue)
- `Coding::Workspace` is what starting a task needs: repositories, `branch_for(repository)` (the
  recorded branch, else `branch_name`), `clone_commands`, the work's sections, notes, dated tasks
- `Coding::Brief` is the plugin's section of the core's task brief (`Runwell::Plugins.agent_brief`):
  the branch, each repository's clone commands, environments and setup notes, then the Code
  tools for reporting back, marked as needing Runwell access (an unattended run has none)
- GitHub (`Connection`, one row; `Oauth`; `Github`, REST, read only but for adding the webhook):
  `Webhook` takes signed deliveries (pull requests, reviews, check suites, deployment statuses,
  labelled issues, pushes), and `Sync` (nightly, and Sync now) catches up on open branches and
  collaborators. A labelled issue becomes `Task.create!(…, requested: true)`, so the core records
  `task.requested` and it comes into Intake. Events on records: `coding.repository_linked`,
  `coding.repository_unlinked`, `coding.progress`, `coding.finished`, `coding.scope_flagged`,
  `coding.pull_request_opened`, `coding.merged`, `coding.reviewed`, `coding.deployed` (on the work)
- `Attention` is the Code page (`AttentionsController`, the nav's Code): failing checks, failed
  deploys, people who left but can still reach a repository. It replaced the home briefing, which
  went in Runwell 5.0. `TimeSuggestion` suggests time from a person's commits on a task
- Slots: `:client_panel`, `:work_panel`, `:task_panel` (tabs: Repositories, and on a task "Work on
  it"), `:portal_work_panel` (Shipped: production deploys of repositories shared with the client).
  A quick action (Repository) links one. Settings › Code is the connection, the webhook, people's
  GitHub usernames and every linked repository

## Tools

`checkout_task`, `log_progress`, `finish_task`, `flag_out_of_scope`, `link_repository`,
`update_repository`, `unlink_repository`, `share_deploys_with_client` (confirms: the client sees
it), `stop_sharing_deploys`, `add_github_webhook`, `sync_github`, `disconnect_github`,
`show_code_settings`, `show_code_attention`, `show_time_suggestions`, `log_suggested_time`,
`dismiss_time_suggestion`, `set_my_github_login`, `set_github_login`. Saving the OAuth app's id
and secret (`SettingsController#update`) and signing in to GitHub are `browser_only`: keys to
another service are a person's to set. Before 1.0, `checkout_task` was `checkout_work`,
`finish_task` was `finish_work`, and `update_code_settings` existed.

A tool runs as the person's agent (`Current.user` is the agent user): what is "yours" goes to
`Current.user.person` (your GitHub username, your time suggestions, unlinking what you linked).

## What other plugins use

The AI plugin's queue (`runwell-ai`, `Ai::Queue.code`) reads these when the plugin is on, and
checks they're defined; keep their names and meaning, or change the AI plugin in step:

- `Coding::Repository.for(task)`: an Array of repositories (`url`, `default_branch`, `path`,
  `name`, `setup_notes`); empty means the task can't be marked ready for AI
- `Coding::Workspace.new(task)`: `repositories`, `branch_name`, `branch_for(repository)`,
  `clone_commands(repository)` (three shell commands, run in order from the directory to clone
  into), served to a runner with each run
- `Coding::Branch.name_for(task)` (the branch its prompt names) and
  `Coding::Branch.record!(task, name:, pull_request_url:)` (what a finished run reports)
- The brief section (`Coding::Brief`), which reaches the run's prompt through the core's
  `Task::Brief`

## Rules

- Views draw with runeui: `ui :card`, `ui :button` (or `class: "ui-button"` with `data-variant` /
  `data-size` on a `button_to`), `ui :empty`, `ui :alert`, `ui :collapsible`, `ui :page_header`,
  `form.ui :field` / `form.ui :input`, and the core's helpers (`status_tag`, `code_block`,
  `rich_text_field`, `secret_field`, `switch_field`, `section_nav`, `layouts/shared/delete_dialog`
  and `confirm`). No rune_ui helpers or classes (the compatibility layer went in Runwell 7.0)
- CSS (`app/assets/stylesheets/coding/code.css`) starts with `/* tokens: runeui */` and reads
  runeui's tokens only (`--muted-foreground`, `--border`, `--muted`, `--primary` for the brand,
  `--ui-*`; `docs/theming.md`). Classes are `code-*`. Spacing in rems
- Tables are prefixed `coding_`, point at core records by id, and migrations are safe on a live
  install. `20261120200000` renamed `engagement_id` to `work_id` and `todo_id` to `task_id` and
  the stored types `Engagement` / `Todo` to `Work` / `Task`; the first two migrations point their
  foreign keys at whichever of the core's tables exists, so a new install starts right
- It never pushes code, merges, or stores secrets; GitHub calls go through `Coding::Github`
- Write for anyone running something: no "agency" or one industry's words in what people read
- Release: bump `lib/coding/version.rb`, commit, tag `vX.Y.Z`, push the tag (the workflow
  publishes the release)
