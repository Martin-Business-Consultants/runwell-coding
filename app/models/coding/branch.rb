module Coding
  # A task's branch in a repo, and its pull request as GitHub last told us.
  class Branch < ::ApplicationRecord
    self.table_name = "coding_branches"

    PR_STATES = %w[draft open merged closed].freeze
    CHECK_STATES = %w[pending success failure].freeze

    belongs_to :task, class_name: "::Task"
    belongs_to :repository

    validates :name, presence: true, uniqueness: { scope: :repository_id }
    validates :pr_state, inclusion: { in: PR_STATES }, allow_nil: true
    validates :checks_state, inclusion: { in: CHECK_STATES }, allow_nil: true

    scope :failing, -> { where(checks_state: "failure", pr_state: %w[draft open]) }
    scope :open_prs, -> { where(pr_state: %w[draft open]) }

    class << self
      # The branch name a task's work goes on: "p-4/58-get-contact-details", or "task/58-…" for a
      # task straight on a client. Before 1.0 that was "work/58-…"; task_from reads both.
      def name_for(task)
        slug = task.title.parameterize.first(40).delete_suffix("-")
        "#{task.work&.ref&.downcase || "task"}/#{task.id}-#{slug}"
      end

      # The task a branch name points at when nobody recorded it: "p-4/58-…" or "58-…".
      def task_from(name)
        id = name.to_s[%r{(?:\A|/)(\d+)-}, 1]
        ::Task.find_by(id: id) if id
      end

      # The branch row for a name pushed to a repo, recorded or worked out from the name.
      def locate(repository, name)
        repository.branches.find_by(name: name) || task_from(name)&.then do |task|
          repository.branches.create!(task: task, name: name) if Repository.for(task).include?(repository)
        end
      end

      # What someone (or the AI queue) reported: the branch a task is on and its pull request, in
      # whichever of the task's repos the pull request belongs to (the first when it doesn't say).
      # Returns the branch, or nil when there's nothing to record or no repository to put it in.
      def record!(task, name:, pull_request_url: nil)
        return if name.blank? && pull_request_url.blank?

        repositories = Repository.for(task)
        repository = repositories.find { pull_request_url.to_s.start_with?(it.web_url + "/") } || repositories.first or return
        branch = repository.branches.find_or_initialize_by(name: name.presence || name_for(task))
        branch.task = task
        if pull_request_url.present?
          branch.pr_url = pull_request_url
          branch.pr_number = pull_request_url[%r{/pull/(\d+)}, 1] || branch.pr_number
          branch.pr_state ||= "open"
        end
        branch.save!
        branch
      end
    end

    def pr_label
      return "No pull request" unless pr_number

      [ "##{pr_number}", pr_state&.humanize, (checks_state && "checks #{checks_state}") ].compact.join(" · ")
    end

    def label = "#{repository.name} #{name}"
    def compare_url = repository.github? ? "#{repository.web_url}/compare/#{repository.default_branch}...#{name}?expand=1" : nil
  end
end
