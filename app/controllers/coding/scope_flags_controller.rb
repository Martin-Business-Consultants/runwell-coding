# When a task goes beyond what was agreed: a new task on the client, internal and unassigned, in
# Intake for someone to take on or decline. The client sees nothing.
module Coding
  class ScopeFlagsController < ApplicationController
    allow_staff
    agent_tool :flag_out_of_scope, on: :create, title: "Flag work that looks outside the agreed scope",
      description: "Compare the work (the diff, or what was asked for) with the task and its work's sections from checkout_task. When it goes beyond them, flag it: this adds an internal task on the client, in Intake, for someone to take on or decline. The client sees nothing.",
      params: { scope_flag: { summary: "string!", details: "text" } }

    before_action :set_task

    def create
      flag = params.expect(scope_flag: %i[summary details])
      raised_on = [ @task.work&.title, @task.title ].compact.join(": ")
      flagged = ::Task.new(client: @task.client, title: "Beyond scope? #{flag[:summary]}".truncate(200), source: "scope check",
        client_visible: false, created_by: Current.user,
        description: [ flag[:details], "<p>Raised on #{ERB::Util.html_escape(raised_on)}</p>" ].compact_blank.join)
      if flagged.save
        @task.record_event!("coding.scope_flagged", payload: { task: flagged.id })
        redirect_back fallback_location: @task, notice: "Flagged: “#{flagged.title}” is in Intake, internal, for someone to take on or decline."
      else
        redirect_back fallback_location: @task, alert: flagged.errors.full_messages.to_sentence
      end
    end
  end
end
