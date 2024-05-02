class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
  
    if @user.save
      render json: { user: @user, notice: 'User was successfully created.' }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private

  def user_params
    params.require(:user).permit(:tracking_number, :aftership_status, :expected_delivery_date)
  end
end
