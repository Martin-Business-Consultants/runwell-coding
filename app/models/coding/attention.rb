module Coding
  # What the Code page (AttentionsController) lists: open pull requests with failing checks, the
  # latest deploy to an environment when it failed, and people who have left but can still reach
  # a linked repo. (Runwell's home page showed these until it went in 5.0.)
  module Attention
    def self.failing_branches = Branch.failing.includes(:repository, task: %i[work client]).order(:updated_at).to_a

    def self.failed_deploys
      latest = Deploy.where(id: Deploy.group(:repository_id, :environment).select("max(id)"))
      latest.failed.includes(repository: :client).recent.to_a.uniq { [ it.repository.full_name, it.environment ] }
    end

    def self.departed = Collaborator.departed.includes(:repository).order(:login).to_a.uniq { [ it.repository.full_name, it.login ] }

    def self.items = failing_branches + failed_deploys + departed
  end
end
