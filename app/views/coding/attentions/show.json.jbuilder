json.summary [ (@failing.any? && "#{@failing.size} pull #{"request".pluralize(@failing.size)} with failing checks"),
  (@deploys.any? && "#{@deploys.size} failed #{"deploy".pluralize(@deploys.size)}"),
  (@departed.any? && "#{@departed.size} #{"person".pluralize(@departed.size)} who left can still reach a repository") ].select(&:present?).to_sentence.presence || "Nothing needs attention"
json.failing_checks @failing do |branch|
  json.task agent_ref(branch.task)
  json.repository branch.repository.name
  json.extract! branch, :name, :pr_number, :pr_url, :pr_state, :checks_state
end
json.failed_deploys @deploys do |deploy|
  json.repository deploy.repository.name
  json.client agent_ref(deploy.repository.client)
  json.extract! deploy, :environment, :state, :sha, :url, :deployed_at
end
json.departed @departed do |collaborator|
  json.name @names[collaborator.login]
  json.github_login collaborator.login
  json.repository collaborator.repository.name
  json.access_url "#{collaborator.repository.web_url}/settings/access"
end
