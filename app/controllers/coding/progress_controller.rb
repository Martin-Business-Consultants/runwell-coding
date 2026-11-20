# Reporting on a task from the terminal: a note on it, and optionally its status and branch.
module Coding
  class ProgressController < ApplicationController
    allow_staff
    agent_tool :log_progress, on: :create, title: "Report progress on a task",
      description: "Adds a note to the task. status moves it (planned, in_progress, in_review, blocked, done). branch and pull_request_url record where the work is.",
      params: { progress: { note: "text!", status: ::Task::STATUSES, branch: "string", pull_request_url: "string" } }

    before_action :set_task

    def create
      progress = params.expect(progress: %i[note status branch pull_request_url])
      return redirect_back(fallback_location: @task, alert: "Say what happened.") if progress[:note].blank?

      ::Task.transaction do
        @task.notes.create!(body: progress[:note], kind: "internal", source: Current.source || "app", author: Current.user)
        Branch.record!(@task, name: progress[:branch], pull_request_url: progress[:pull_request_url])
        @task.update!(status: progress[:status]) if progress[:status].present? && progress[:status] != @task.status
        @task.record_event!("coding.progress", payload: { branch: progress[:branch] }.compact)
      end
      redirect_back fallback_location: @task, notice: "Progress noted on “#{@task.title}” (#{@task.status.humanize.downcase})."
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: @task, alert: e.record.errors.full_messages.to_sentence
    end
  end
end
