# Runwell 3.0: requests are work, so a GitHub issue now becomes a todo. request_id stays for the
# issues that came in before, so none of them arrives twice.
class AddTodoToCodingIssues < ActiveRecord::Migration[8.1]
  def change
    add_reference :coding_issues, :todo, foreign_key: true
  end
end
