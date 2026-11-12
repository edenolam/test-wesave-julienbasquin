class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { errors: [ "Resource not found" ] }, status: :not_found
  end

  rescue_from ActiveRecord::RecordNotUnique do
    render json: { errors: [ "Resource already exists" ] }, status: :unprocessable_entity
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render json: { errors: error.record.errors.full_messages }, status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing, ActionController::BadRequest do |error|
    render json: { errors: [ error.message ] }, status: :bad_request
  end
end
