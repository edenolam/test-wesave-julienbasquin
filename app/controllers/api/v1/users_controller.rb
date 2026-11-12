module Api
  module V1
    class UsersController < ApplicationController
      def create
        user = User.create!(params.require(:user).permit(:email, :password))
        render json: user.as_json(only: %i[id email]), status: :created
      end
    end
  end
end
