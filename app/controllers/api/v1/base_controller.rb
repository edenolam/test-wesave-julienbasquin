module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      attr_reader :current_user, :current_session

      def authenticate_user!
        token = request.authorization.to_s[/\ABearer ([a-f0-9]{64})\z/, 1]
        @current_session = ApiSession.where("expires_at > ?", Time.current)
          .find_by(token_digest: Digest::SHA256.hexdigest(token)) if token
        @current_user = current_session&.user
        render json: { errors: [ "Authentication required" ] }, status: :unauthorized unless current_user
      end

      def paginated(scope)
        offset = Integer(params.fetch(:offset, "0"), exception: false)
        raise ActionController::BadRequest, "Invalid offset" unless offset && offset.between?(0, 1_000_000)
        scope.limit(50).offset(offset)
      end

      def portfolio
        @portfolio ||= current_user.portfolios.find(params[:portfolio_id] || params[:id])
      end
    end
  end
end
