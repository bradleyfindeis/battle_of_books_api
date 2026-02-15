class TeammatesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_team_lead!
  before_action :set_teammate, only: [:update, :destroy, :reset_pin]

  def index
    teammates = @current_user.team.teammates.includes(:book_assignments)
    render json: teammates.map { |t|
      data = UserSerializer.new(t).as_json
      data[:assignment_count] = t.book_assignments.size
      data[:completed_count] = t.book_assignments.completed.size
      data
    }
  end

  def create
    teammate = @current_user.team.users.build(username: params[:username], role: :teammate, pin_reset_required: true)
    custom_pin = params[:pin].to_s
    if custom_pin.present? && custom_pin.match?(/\A\d{4}\z/)
      teammate.pin_code = custom_pin
    end
    if teammate.save
      pin = custom_pin.present? ? custom_pin : teammate.generate_pin!
      render json: { user: UserSerializer.new(teammate).as_json, pin: pin }, status: :created
    else
      render json: { errors: teammate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @teammate.update(teammate_params)
      render json: UserSerializer.new(@teammate).as_json
    else
      render json: { errors: @teammate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @teammate.destroy
    head :no_content
  end

  def reset_pin
    new_pin = params[:new_pin].to_s
    if new_pin.present?
      unless new_pin.match?(/\A\d{4}\z/)
        return render json: { error: 'PIN must be exactly 4 digits' }, status: :unprocessable_entity
      end
      @teammate.update!(pin_code: new_pin, pin_reset_required: false)
      pin = new_pin
    else
      pin = @teammate.generate_pin!
    end
    render json: { user: UserSerializer.new(@teammate).as_json, pin: pin, message: "PIN updated for #{@teammate.username}: #{pin}" }
  end

  private
  def set_teammate
    @teammate = @current_user.team.teammates.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Teammate not found' }, status: :not_found
  end
  def teammate_params
    params.require(:teammate).permit(:username, :pin)
  end
end
