# The Code page (the nav's Code): what needs someone across every linked repository. Pull
# requests whose checks fail, environments whose latest deploy failed, and people who left but can
# still reach a repo.
module Coding
  class AttentionsController < ApplicationController
    allow_staff
    agent_tool :show_code_attention, on: :show, title: "Show what needs attention in code",
      description: "Open pull requests with failing checks (with their task), environments whose latest deploy failed, and deactivated people who can still reach a linked GitHub repository."

    def show
      @failing = Attention.failing_branches
      @deploys = Attention.failed_deploys
      @departed = Attention.departed
      @names = Identity.includes(:user).where(github_login: @departed.map(&:login)).to_h { [ it.github_login, it.user.display_name ] }
    end
  end
end
