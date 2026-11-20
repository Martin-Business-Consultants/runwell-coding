# Runwell 5.0 renamed engagements to work and todos to tasks, and moved its own tables, columns and
# stored types; these are the Code plugin's:
# - coding_repositories.engagement_id becomes work_id, and a repository linked to an "Engagement"
#   or a "Todo" is linked to a "Work" or a "Task" (linkable_type)
# - todo_id becomes task_id on coding_branches, coding_commits and coding_issues
# Ids don't change (the core kept them), and the foreign keys follow their columns. Each step
# checks first, so it's safe on an install part-way there and running it again changes nothing.
class RenameCodingToWorkAndTasks < ActiveRecord::Migration[8.1]
  RENAMES = {
    coding_repositories: { engagement_id: :work_id },
    coding_branches: { todo_id: :task_id },
    coding_commits: { todo_id: :task_id },
    coding_issues: { todo_id: :task_id }
  }.freeze

  TYPES = { "Engagement" => "Work", "Todo" => "Task" }.freeze

  def up
    RENAMES.each do |table, columns|
      columns.each do |from, to|
        rename_column table, from, to if column_exists?(table, from) && !column_exists?(table, to)
      end
    end
    TYPES.each do |from, to|
      execute "UPDATE coding_repositories SET linkable_type = #{quote(to)} WHERE linkable_type = #{quote(from)}"
    end
  end

  def down
    RENAMES.each do |table, columns|
      columns.each do |from, to|
        rename_column table, to, from if column_exists?(table, to) && !column_exists?(table, from)
      end
    end
    TYPES.each do |from, to|
      execute "UPDATE coding_repositories SET linkable_type = #{quote(from)} WHERE linkable_type = #{quote(to)}"
    end
  end

  private
    def quote(value) = connection.quote(value)
end
