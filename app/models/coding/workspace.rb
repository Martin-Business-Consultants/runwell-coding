module Coding
  # Everything someone (or an agent) needs to start a task on their own machine: where the code
  # is and how to set it up, the branch to work on, and its work's sections, so the task is
  # measured against what the work delivers rather than a guess. The AI queue (runwell-ai) builds
  # a run's repositories and clone commands from it too.
  class Workspace
    attr_reader :task

    def initialize(task)
      @task = task
    end

    def work = task.work
    def repositories = @repositories ||= Repository.for(task)
    def source = Repository.source_for(task)
    def branch_name = Branch.name_for(task)
    def branches = @branches ||= task.coding_branches.includes(:repository).index_by(&:repository_id)
    # The branch already recorded for the task in this repo, else the one it should go on.
    def branch_for(repository) = branches[repository.id]&.name || branch_name

    # Run in order from the directory to clone into: clone, go to the project's folder, and switch
    # to the task's branch (made from the default branch when it isn't there yet).
    def clone_commands(repository)
      directory = repository.name.split("/").last
      branch = branch_for(repository)
      [ "git clone #{repository.url} #{directory}", "cd #{[ directory, repository.path ].compact.join("/")}",
        "git switch #{branch} 2>/dev/null || git switch -c #{branch} origin/#{repository.default_branch}" ]
    end

    # The work's sections, in order. A task straight on a client has none.
    def sections = work ? work.scope_items.order(:position).to_a : []

    def notes = task.notes.recent.includes(:author).limit(10)
    # Other open tasks with a date on the same work (or client): what's been promised around it.
    def dated_tasks = (work&.tasks || task.client&.tasks || ::Task.none).open.where.not(id: task.id).where.not(due_on: nil).includes(:owner).order(:due_on).limit(20)
    def documents = task.documents.recent + (work&.documents&.recent || [])
  end
end
