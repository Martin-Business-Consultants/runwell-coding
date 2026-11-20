# Code for Runwell

Git repositories on clients, work and tasks; GitHub pull requests, checks, deploys and issues; branches and briefs for coding agents.

A plugin for [Runwell](https://github.com/Martin-Business-Consultants/runwellv2), the core of an
agency's project management. It owns its tables (`coding_*`), points at core records by id, and
extends Runwell only through its plugin hooks, so removing it leaves Runwell as it was.

## Install

In Runwell, **Settings > Plugins > Add a plugin**: press Install on Code, or enter
`Martin-Business-Consultants/runwell-coding`. Runwell downloads the latest release onto the server, restarts and creates the
plugin's tables. It starts off: switch it on in Settings > Plugins.

From the command line on the server: `bin/rails "plugins:install[Martin-Business-Consultants/runwell-coding]"`, then restart
Runwell.

Needs Runwell 6.0.0 or later (1.0.0; 0.2.0 was the last for Runwell 3.0 to 4.x). A plugin can use
only the gems Runwell bundles. Updating from 0.2.0 renames its columns to Runwell 5.0's nouns
(`engagement_id` to `work_id`, `todo_id` to `task_id`) on its own tables.

## What it does

- **Repositories** on a client, a piece of work or a task (the quick actions, A, under
  Repository; the Code tab on each). A task uses its work's repositories unless it has its own,
  and a piece of work its client's. Any git remote; setup notes say where secrets live, never the
  secrets.
- **Starting a task** on your own machine: its Code tab, `runwell checkout_task --task_id 58`, or
  the task's brief (the core's AI button), which carries the clone commands and the branch
  (`p-4/58-contact-form`). `log_progress`, `finish_task` (puts it in review) and
  `flag_out_of_scope` (an internal task in Intake) report back.
- **With GitHub connected** (Settings › Code, your own OAuth app): pull requests and checks on
  each task's branch (a merge can mark the task done), production deploys on the work's history
  and, when shared, in the client portal, issues with a label as requests in Intake, commits as
  time suggestions (logged with the Time tracking plugin), and the Code page (in the nav) listing
  failing checks, failed deploys and people who left but can still reach a repository.
- **The AI queue** (the AI plugin, 3.1 or later) needs it: a task is ready for an unattended agent
  only once it has a repository here, and each run is told the repositories, their clone
  commands and the branch.

## Updating

Settings > Plugins shows an Update button on the plugin when a newer release is out (it checks
nightly, or with Check for updates). The plugin updates only when someone presses it; if the new
release won't load, the previous one comes back.

## Developing

Clone this repository beside a Runwell checkout and link it in, from Runwell's directory:

```sh
bin/rails "plugins:link[../runwell-coding]"
bin/rails db:migrate
bin/dev
```

Then switch it on in Settings › Plugins. `AGENTS.md` is the guide for working on it.

## Releasing

Bump `VERSION` in `lib/coding/version.rb`, commit, then tag and push the tag:

```sh
git tag v1.0.0 && git push origin main v1.0.0
```

The release workflow (`.github/workflows/release.yml`) checks the tag matches the version and
publishes the GitHub release; installs see it in Settings › Plugins.

## License

[FSL-1.1-MIT](LICENSE.md), like Runwell.
