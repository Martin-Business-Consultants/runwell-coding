module Coding
  # A GitHub issue that became a request (a task in Intake), so the same issue never arrives
  # twice. request_id is from before Runwell 3.0, when requests were records of their own.
  class Issue < ::ApplicationRecord
    self.table_name = "coding_issues"

    belongs_to :repository
    belongs_to :task, class_name: "::Task", optional: true
  end
end
