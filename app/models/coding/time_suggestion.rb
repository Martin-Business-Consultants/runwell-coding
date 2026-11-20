module Coding
  # Time worth logging, worked out from commits: one person's commits on one task on one day,
  # from the first to the last plus a half hour lead-in, to the nearest quarter hour. Only a
  # suggestion; nothing is logged until someone says so.
  class TimeSuggestion
    LEAD_IN = 30

    attr_reader :user, :task, :date, :commits

    # A person's suggestions (an agent's are its person's: commits are matched to people).
    def self.for(user)
      Commit.unsettled.where(user: user.person).includes(task: %i[work client]).order(:committed_at).to_a
        .group_by { [ it.task, it.committed_at.in_time_zone.to_date ] }
        .map { |(task, date), commits| new(user.person, task, date, commits) }
        .sort_by(&:date).reverse
    end

    def initialize(user, task, date, commits)
      @user, @task, @date, @commits = user, task, date, commits
    end

    def id = "#{task.id}-#{date.iso8601}"

    def minutes
      span = ((commits.last.committed_at - commits.first.committed_at) / 60).round
      ((span + LEAD_IN) / 15.0).round * 15
    end

    def note = "#{commits.size} #{"commit".pluralize(commits.size)}: #{commits.map(&:message).compact.map { it.lines.first.strip }.uniq.first(3).join("; ")}".truncate(250)

    def settle!(as)
      Commit.where(id: commits.map(&:id)).update_all(as => Time.current)
    end
  end
end
