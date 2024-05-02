class ShipmentsController < ApplicationController
  before_action :initialize_aftership_client

  def initialize_aftership_client
    AfterShip.api_key = 'asat_827052647db34cae829f6d8422a595f9'
  end

  def track_shipment
    tracking_number = params[:tracking_number]
    carrier_name = params[:carrier_name]
    tracking_info = AfterShip::V4::Tracking.get(tracking_number, carrier_name)
 end

  def aftership
    Rails.logger.info(request) if request&.present?
    Rails.logger.info(params) if params&.present?

    request_body = request.body.read
    Rails.logger.info "Received webhook data: #{request_body}" if request_body.present?

    if request_body.present?
      begin
        params = JSON.parse(request_body)
        tracking_number = params["shipments"]["msg"]["tracking_number"]
        status = params["shipments"]["msg"]["tag"] 
        expected_delivery = params["shipments"]["msg"]["expected_delivery"]

        order = User.find_by(tracking_number: tracking_number)
        if order
          order.update!(aftership_status: status, expected_delivery_date: expected_delivery)
          render json: { status: 'success' }, status: :ok
        else
          render json: { error: 'Order not available' }, status: :not_found
        end
      rescue JSON::ParserError => e
        render json: { error: 'Invalid JSON data in request body' }, status: :bad_request
      end
    else
      render json: { error: 'Empty request body' }, status: :bad_request
    end
  end
end
