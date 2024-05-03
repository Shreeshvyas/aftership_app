class ShipmentsController < ApplicationController
  require 'uri'
  require 'net/http'

  before_action :initialize_aftership_client
  # before_action :verify_webhook_signature, only: [:aftership]

  def initialize_aftership_client
    AfterShip.api_key = 'asat_f6e9f63454854a6093d2f28a0007c5bd'
  end

  def track_shipment
    tracking_number = params[:tracking_number]
    slug = params[:carrier_name]
    url = URI("https://api.aftership.com/tracking/2024-04/last_checkpoint/#{slug}/#{tracking_number}")
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(url)
    request["as-api-key"] ="asat_f6e9f63454854a6093d2f28a0007c5bd"
    request["cache-control"] = 'no-cache'
    
    response = http.request(request)
    if response
      render json: response, status: :ok
    else
      render json: { error: 'No response' }, status: :not_found
    end
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
        order = User.find_or_create_by(tracking_number: trac_num)
        if order
          order.update!(aftership_status: status)
          render json: order, status: :ok
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
    details = AfterShip::V4::Tracking.create(new_tracking_number.to_s, { emails: ["jank@gmail.com"] })
    user.update(tracking_number: new_tracking_number, slug: details["data"]["tracking"]["slug"], tag: details["data"]["tracking"]["tag"], expected_delivery_date: details["data"]["tracking"]["expected_delivery"])
  
    render json: { status: 'success', tracking_number: new_tracking_number, slug: details["data"]["tracking"]["slug"], tag: details["data"]["tracking"]["tag"], expected_delivery_date: details["data"]["tracking"]["expected_delivery"]}, status: :ok
  end
  

  # private

  # def verify_webhook_signature
  #   provided_signature = request.headers['aftership-signature']
  #   request_body = request.body.read

  #   unless request_body.nil?
  #     expected_signature = OpenSSL::HMAC.hexdigest('sha256', ENV['AFTERSHIP_WEBHOOK_SECRET_KEY'], request_body)

  #     unless ActiveSupport::SecurityUtils.secure_compare(provided_signature, expected_signature)
  #       head :unauthorized
  #     end
  #   else
  #     head :bad_request
  #   end
  # end  
end
