module Api
  module V1
    class TradesController < BaseController
      def index
        render json: paginated(portfolio.trades.order(executed_at: :desc, id: :desc)).as_json(only: fields)
      end

      def create
        trade = portfolio.trades.create!(params.require(:trade).permit(:asset_id, :side, :quantity, :unit_price, :executed_at))
        render json: trade.as_json(only: fields), status: :created
      end

      private

      def fields
        %i[id asset_id side quantity unit_price executed_at]
      end
    end
  end
end
