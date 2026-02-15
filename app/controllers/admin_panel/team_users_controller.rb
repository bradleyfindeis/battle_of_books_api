# frozen_string_literal: true

module AdminPanel
  class TeamUsersController < BaseController
    before_action :set_team
    before_action :set_user, only: [:update, :destroy, :reset_credential]

    # POST /admin/teams/:team_id/users
    def create
      role = params[:role].to_s.presence&.then { |r| r == 'team_lead' ? :team_lead : :teammate }
      user = @team.users.build(user_create_params(role))
      user.role = role

      if role == :team_lead
        password = params[:password].to_s
        if password.blank? || password.length < 6
          return render json: { errors: ['Password is required and must be at least 6 characters'] }, status: :unprocessable_entity
        end
        user.pin_code = password
        user.pin_reset_required = false
      else
        custom_pin = params[:pin].to_s
        if custom_pin.present? && custom_pin.match?(/\A\d{4}\z/)
          user.pin_code = custom_pin
        end
        user.pin_reset_required = custom_pin.blank?
      end

      if user.save
        data = UserSerializer.new(user).as_json
        if role == :teammate
          data[:pin] = (custom_pin.present? && custom_pin.match?(/\A\d{4}\z/)) ? custom_pin : user.generate_pin!
        end
        render json: { user: data }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /admin/teams/:team_id/users/:id
    def update
      if params[:role].present?
        new_role = params[:role].to_s == 'team_lead' ? :team_lead : :teammate
        if new_role == :team_lead
          @team.team_lead&.update!(role: :teammate)
          @user.update!(role: :team_lead)
        else
          @user.update!(role: :teammate)
        end
      end
      if params[:username].present?
        @user.update!(username: params[:username])
      end
      if params[:email].present? && @user.team_lead?
        @user.update!(email: params[:email])
      end
      render json: UserSerializer.new(@user.reload).as_json
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    # DELETE /admin/teams/:team_id/users/:id
    def destroy
      @user.destroy
      head :no_content
    end

    # POST /admin/teams/:team_id/users/:id/reset_credential
    def reset_credential
      if @user.team_lead?
        new_password = params[:new_password].to_s
        if new_password.blank?
          return render json: { errors: ["Password can't be blank"] }, status: :unprocessable_entity
        end
        if new_password.length < 6
          return render json: { errors: ['Password must be at least 6 characters'] }, status: :unprocessable_entity
        end
        @user.update!(pin_code: new_password, pin_reset_required: false)
        render json: { user: UserSerializer.new(@user).as_json }
      else
        new_pin = params[:new_pin].to_s
        if new_pin.present?
          unless new_pin.match?(/\A\d{4}\z/)
            return render json: { errors: ['PIN must be exactly 4 digits'] }, status: :unprocessable_entity
          end
          @user.update!(pin_code: new_pin, pin_reset_required: false)
          render json: { user: UserSerializer.new(@user).as_json }
        else
          generated_pin = @user.generate_pin!
          render json: { user: UserSerializer.new(@user).as_json, pin: generated_pin }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def set_team
      @team = Team.find(params[:team_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Team not found' }, status: :not_found
    end

    def set_user
      @user = @team.users.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'User not found' }, status: :not_found
    end

    def user_create_params(role)
      permitted = [:username]
      permitted << :email if role == :team_lead
      params.permit(permitted)
    end
  end
end
