module Coding
  class ApplicationController < ::ApplicationController
    layout "application"

    before_action { head :not_found unless Runwell::Plugins.enabled?(:coding) }

    private
      def set_task = @task = ::Task.find(params[:task_id])
  end
end
