class ShipmentsController < ApplicationController
  before_action :initialize_aftership_client
  before_action :verify_webhook_signature, only: [:aftership]

  def initialize_aftership_client
    AfterShip.api_key = 'asak_cef9b553b85b424394df7fa200cc4c57'
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
        trac_num = params.dig("msg", "tracking_number")
        status = params.dig("msg", "tag") 
        expected_delivery = params.dig("msg", "expected_delivery")
        order = User.find_by(tracking_number: trac_num)
      
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

  def create_trackings
    user = User.find_by(id: params[:user_id])
    tracking_num = SecureRandom.random_number(10_000_000..99_999_999)
    tracking = Tracking.find_or_create_by(date: DateTime.current, status: "Initiated", tracking_number: tracking_num)
    new_tracking_number = Tracking.last.tracking_number
    details = AfterShip::V4::Tracking.create(new_tracking_number.to_s, { emails: ["xyadscz@gmail.com"] })
    user.update(tracking_number: new_tracking_number, slug: details["data"]["tracking"]["slug"], tag: details["data"]["tracking"]["tag"], expected_delivery_date: details["data"]["tracking"]["expected_delivery"])
  
    render json: { status: 'success', tracking_number: new_tracking_number, slug: details["data"]["tracking"]["slug"], tag: details["data"]["tracking"]["tag"], expected_delivery_date: details["data"]["tracking"]["expected_delivery"]}, status: :ok
  end
  
  private

  def verify_webhook_signature
    provided_signature = request.headers['aftership-signature']
    request_body = request.body.read
  
    if request_body.nil? || request_body.empty?
      render json: { error: 'Empty request body' }, status: :bad_request
      return
    end
  
    expected_signature = OpenSSL::HMAC.hexdigest('sha256', ENV['AFTERSHIP_WEBHOOK_SECRET_KEY'], request_body)
  
    unless ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
  end    
end
