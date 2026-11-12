module Api
  module V1
    class AssetsController < BaseController
      def index
        render json: paginated(Asset.order(:id)).as_json(only: %i[id isin name asset_type])
      end

      def prices
        asset = Asset.find(params[:id])
        render json: paginated(asset.prices.order(quoted_on: :desc)).as_json(only: %i[id value quoted_on])
      end
    end
  end
end
