module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: :create
      rate_limit to: 10, within: 1.minute, only: :create,
        store: ActiveSupport::Cache::MemoryStore.new,
        with: -> { render json: { errors: [ "Too many login attempts" ] }, status: :too_many_requests }

      def create
        credentials = params.require(:session).permit(:email, :password)
        user = User.find_by(email: credentials[:email].to_s.strip.downcase)
        if user&.authenticate(credentials[:password].to_s)
          render json: { token: ApiSession.issue!(user), expires_in: 86_400 }, status: :created
        else
          render json: { errors: [ "Invalid credentials" ] }, status: :unauthorized
        end
      end

      def destroy
        current_session.destroy!
        head :no_content
      end
    end
  end
end
