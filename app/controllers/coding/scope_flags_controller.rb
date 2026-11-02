# When work goes beyond what the client agreed: new work on the client that nobody has taken on
# (a request, in Requests), for someone to assign or delete. Internal: the client sees nothing.
module Coding
  class ScopeFlagsController < ApplicationController
    allow_staff
    agent_tool :flag_out_of_scope, on: :create, title: "Flag work that looks outside the agreed scope",
      description: "Compare the work (the diff, or what was asked for) with the agreed scope from checkout_work. When it goes beyond it, flag it: this adds unassigned, internal work on the client (a request, in Requests) for someone to assign or delete. The client sees nothing.",
      params: { scope_flag: { summary: "string!", details: "text" } }

    before_action :set_todo

    def create
      flag = params.expect(scope_flag: %i[summary details])
      raised_on = [ @todo.engagement&.ref, @todo.title ].compact.join(": ")
      request = ::Todo.new(client: @todo.client, title: "Beyond scope? #{flag[:summary]}".truncate(200), source: "scope check",
        client_visible: false, created_by: Current.user,
        description: [ flag[:details], "<p>Raised on #{ERB::Util.html_escape(raised_on)}</p>" ].compact_blank.join)
      if request.save
        request.record_event!("todo.requested", payload: { todo: @todo.id })
        @todo.record_event!("coding.scope_flagged", payload: { request: request.id })
        redirect_back fallback_location: @todo, notice: "Flagged as a request: unassigned work on the client, in Requests. Assign someone, or draft a change order if the client should agree to it."
      else
        redirect_back fallback_location: @todo, alert: request.errors.full_messages.to_sentence
      end
    end
  end
end
