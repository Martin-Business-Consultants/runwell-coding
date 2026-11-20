workspace = @workspace
json.summary workspace.repositories.any? ? "#{@task.title}: #{workspace.repositories.map(&:name).to_sentence}, branch #{workspace.branch_name}" : "#{@task.title}: no repository linked on the task, its work or its client"
json.task do
  json.partial! "tasks/task", task: @task
  json.description agent_text(@task.description)
end
json.branch workspace.branch_name
json.repositories workspace.repositories do |repository|
  json.merge! agent_ref(repository).except("url")
  json.extract! repository, :url, :default_branch, :path, :staging_url, :production_url
  json.web_url repository.web_url
  json.inherited_from agent_ref(repository.linkable) unless repository.linkable == @task
  json.branch workspace.branch_for(repository)
  json.commands workspace.clone_commands(repository)
  json.setup_notes agent_text(repository.setup_notes)
end
json.sections workspace.sections.map { { description: it.description, this_task: it.id == @task.scope_item_id } }
json.scope_item agent_ref(@task.scope_item)
json.dated_tasks workspace.dated_tasks do |task|
  json.merge! agent_ref(task)
  json.extract! task, :status, :due_on
  json.owner task.owner&.display_name
end
json.notes workspace.notes, partial: "notes/note", as: :note
json.documents workspace.documents, partial: "documents/document", as: :document
