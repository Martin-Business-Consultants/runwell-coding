# A task's workspace: the repos to clone, the branch to work on, how to set up, and what its work
# delivers. The page shows the commands; an agent calls checkout_task and runs them.
module Coding
  class CheckoutsController < ApplicationController
    allow_staff
    agent_tool :checkout_task, on: :show, title: "Get everything needed to start a task locally",
      description: "The repos to clone (inherited from the task's work or client when it has none), the branch to work on, setup notes, environments, and the context: the task, its section, its work's sections, other dated tasks, recent notes and documents. Clone and switch to the branch, then report with log_progress and finish_task. If the work goes beyond what was agreed, say so with flag_out_of_scope.",
      next_tools: %i[log_progress finish_task flag_out_of_scope]

    before_action :set_task

    def show
      @workspace = Workspace.new(@task)
    end
  end
end
