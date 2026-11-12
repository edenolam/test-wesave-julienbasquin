module Api
  module V1
    class PortfoliosController < BaseController
      def index
        render json: paginated(current_user.portfolios.order(:id)).as_json(only: %i[id name currency])
      end

      def show
        render json: portfolio.as_json(only: %i[id name currency])
      end

      def create
        record = current_user.portfolios.create!(params.require(:portfolio).permit(:name, :currency))
        render json: record.as_json(only: %i[id name currency]), status: :created
      end

      def positions
        render json: portfolio.positions
      end

      def valuation
        date = params[:date] ? Date.iso8601(params[:date]) : Date.current
        raise Date::Error if date > Date.current
        render json: portfolio.valuation(on: date)
      rescue Date::Error, TypeError
        render json: { errors: [ "date must be YYYY-MM-DD and not in the future" ] }, status: :bad_request
      end
    end
  end
end
