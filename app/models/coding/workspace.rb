module Coding
  # Everything someone (or an agent) needs to start a todo on their own machine: where the
  # code is and how to set it up, the branch to work on, and the engagement's sections, so the
  # work is measured against what the engagement delivers rather than a guess.
  class Workspace
    attr_reader :todo

    def initialize(todo)
      @todo = todo
    end

    def engagement = todo.engagement
    def repositories = @repositories ||= Repository.for(todo)
    def source = Repository.source_for(todo)
    def branch_name = Branch.name_for(todo)
    def branches = todo.coding_branches.includes(:repository).index_by(&:repository_id)
    def branch_for(repository) = branches[repository.id]&.name || branch_name

    def clone_commands(repository)
      directory = repository.name.split("/").last
      [ "git clone #{repository.url} #{directory}", "cd #{[ directory, repository.path ].compact.join("/")}",
        "git switch #{branch_for(repository)} 2>/dev/null || git switch -c #{branch_for(repository)} origin/#{repository.default_branch}" ]
    end

    # The engagement's sections, in order. Work straight on a client has none.
    def sections = engagement ? engagement.scope_items.order(:position).to_a : []

    def notes = todo.notes.recent.includes(:author).limit(10)
    # Other open work with a date on the same engagement (or client): what's been promised around it.
    def dated_work = (engagement&.todos || todo.client&.todos || ::Todo.none).open.where.not(id: todo.id).where.not(due_on: nil).includes(:owner).order(:due_on).limit(20)
    def documents = todo.documents.recent + (engagement&.documents&.recent || [])
  end
end
