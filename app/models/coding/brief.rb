module Coding
  # The Code plugin's section of a task's brief (Runwell::Plugins.agent_brief, read by the core's
  # Task::Brief and so by the AI queue's prompt): where the code is, how to get it onto this
  # machine on the right branch, setup notes, and the Code tools for reporting back. The reporting
  # commands need Runwell access, which an unattended run (the AI queue) doesn't have: they say
  # so, as the core's "Working with Runwell" does.
  module Brief
    def self.call(task, base_url)
      workspace = Workspace.new(task)
      repositories = workspace.repositories.to_a
      return if repositories.empty?

      on = "--on #{base_url.to_s.chomp("/").sub(%r{\Ahttps?://}, "")}"
      branches = repositories.map { workspace.branch_for(it) }.uniq
      repos = repositories.map do |repository|
        setup = repository.setup_notes.present? ? "\n\nSetup notes:\n\n#{ActionText::Content.new(repository.setup_notes).to_plain_text.strip}" : ""
        envs = [ ("staging #{repository.staging_url}" if repository.staging_url.present?), ("production #{repository.production_url}" if repository.production_url.present?) ].compact
        <<~MD.strip
          ### #{repository.name}

          Default branch `#{repository.default_branch}`#{", in the folder `#{repository.path}`" if repository.path}. To clone it and switch to the branch:

          ```sh
          #{workspace.clone_commands(repository).join("\n")}
          ```
          #{"\nEnvironments: #{envs.join(" · ")}" if envs.any?}#{setup}
        MD
      end

      <<~MD.strip
        ## Code

        #{branches.one? ? "Work on the branch `#{branches.first}`" : "Work on each repository's branch (below)"} and open a pull request from it: Runwell follows its checks and its merge. Don't merge it yourself; a person reviews it.

        #{repos.join("\n\n")}

        ### Reporting with the Code tools

        Part of working with Runwell (below), so only where you have Runwell access; on an unattended run the runner reports for you.

        ```sh
        runwell checkout_task --task_id #{task.id} #{on}       # this context again, as data
        runwell log_progress --task_id #{task.id} --progress.note "What changed" --progress.status in_progress #{on}
        runwell finish_task --task_id #{task.id} --completion.summary "What was done" --completion.pull_request_url <url> #{on}   # puts it in review
        runwell flag_out_of_scope --task_id #{task.id} --scope_flag.summary "What goes beyond the agreed scope" #{on}
        ```
      MD
    end
  end
end
