module Coding
  # A Runwell plugin: git repositories on clients, work and tasks, so a task can be cloned and
  # started from a terminal (checkout_task), with GitHub's pull requests, checks, deploys, issues
  # and repo access brought in once Settings > Code is connected. It owns its tables and extends
  # the core only through Runwell::Plugins, load hooks and events (docs/plugin-contract.md).
  #
  # Other plugins read where a task's code is from Repository.for, Workspace and Branch.name_for /
  # Branch.record! (the AI plugin's queue does; AGENTS.md, "What other plugins use").
  class Engine < ::Rails::Engine
    initializer "coding.routes" do |app|
      app.routes.append do
        scope "code", module: "coding", as: "coding" do
          resource :attention, only: :show
          resource :settings, only: %i[show update destroy]
          resource :authorization, only: %i[create show]
          resource :sync, only: :create
          resource :people, only: :update
          resource :identity, only: :update
          resources :repositories, only: %i[create update destroy] do
            resource :hook, only: :create
            resource :deploy_sharing, only: %i[create destroy]
          end
          resources :tasks, only: [] do
            resource :checkout, only: :show
            resource :progress, only: :create, controller: "progress"
            resource :completion, only: :create
            resource :scope_flag, only: :create
          end
          resources :time_suggestions, only: %i[index create]
          resource :time_dismissal, only: :create
          post "github/webhooks", to: "webhooks#create", as: :github_webhooks
        end
      end
    end

    initializer "coding.helpers" do
      ActiveSupport.on_load(:action_view) { include Coding::CodeHelper }
    end

    initializer "coding.models" do
      ActiveSupport.on_load(:runwell_task) do
        has_many :coding_repositories, class_name: "Coding::Repository", as: :linkable, dependent: :destroy
        has_many :coding_branches, class_name: "Coding::Branch", dependent: :destroy
        has_many :coding_commits, class_name: "Coding::Commit", dependent: :nullify
        has_many :coding_issues, class_name: "Coding::Issue", dependent: :nullify
      end
      ActiveSupport.on_load(:runwell_work) { has_many :coding_repositories, class_name: "Coding::Repository", as: :linkable, dependent: :destroy }
      ActiveSupport.on_load(:runwell_client) { has_many :coding_repositories, class_name: "Coding::Repository", as: :linkable, dependent: :destroy }
      ActiveSupport.on_load(:runwell_user) { has_one :coding_identity, class_name: "Coding::Identity", dependent: :destroy }
    end

    config.to_prepare do
      Runwell::Plugins.register :coding, name: "Code", version: Coding::VERSION, author: "Runwell",
        enabled_by_default: false, requires: ">= 6.0.0", homepage: "https://github.com/Martin-Business-Consultants/runwell-coding",
        description: "Link git repositories to clients, work and tasks so an agent can clone and start from a task. With GitHub connected: pull requests and checks on tasks, deploys on the timeline, issues as requests, time suggested from commits, and repo access to review when someone leaves."
      Runwell::Plugins.agent_brief :coding, ->(task, base_url) { Coding::Brief.call(task, base_url) }
      Runwell::Plugins.settings :coding, "Code", -> { coding_settings_path }
      Runwell::Plugins.nav :coding, "Code", -> { coding_attention_path }, icon: "monitor"
      Runwell::Plugins.slot :client_panel, :coding, "coding/slots/client_panel"
      Runwell::Plugins.slot :work_panel, :coding, "coding/slots/work_panel"
      Runwell::Plugins.slot :task_panel, :coding, "coding/slots/task_panel"
      Runwell::Plugins.slot :portal_work_panel, :coding, "coding/slots/portal_work_panel"
      Runwell::Plugins.quick_action :coding, label: "Repository", title: "Link a repository", icon: "monitor", partial: "coding/quick_actions/repository",
        types: Coding::Repository::LINKABLE_TYPES, context: ->(record) { Coding::Repository.linkable_for(record) }
      Runwell::Plugins.nightly :coding, -> { Coding::SyncJob.perform_later }
      Runwell::Plugins.stylesheet :coding, "coding/code"
    end
  end
end
