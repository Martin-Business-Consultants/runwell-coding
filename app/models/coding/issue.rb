module Coding
  # A GitHub issue that became a request (work nobody has taken on yet), so the same issue never
  # arrives twice. request_id is from before 3.0, when requests were records of their own.
  class Issue < ::ApplicationRecord
    self.table_name = "coding_issues"

    belongs_to :repository
    belongs_to :todo, class_name: "::Todo", optional: true
  end
end
