module AdminPanel
  class InviteCodesController < BaseController
    before_action :set_invite_code, only: [:show, :update, :destroy]

    def index
      codes = InviteCode.includes(:teams).order(created_at: :desc)
      render json: codes.map { |c| InviteCodeSerializer.new(c).as_json }
    end

    def show
      render json: InviteCodeSerializer.new(@invite_code, include_teams: true).as_json
    end

    def create
      code = @current_admin.invite_codes.build(invite_code_params)
      if code.save
        render json: InviteCodeSerializer.new(code).as_json, status: :created
      else
        render json: { errors: code.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if @invite_code.update(invite_code_params)
        render json: InviteCodeSerializer.new(@invite_code).as_json
      else
        render json: { errors: @invite_code.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @invite_code.destroy
      head :no_content
    end

    private
    def set_invite_code
      @invite_code = InviteCode.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Invite code not found' }, status: :not_found
    end
    def invite_code_params
      params.permit(:name, :code, :max_uses, :expires_at, :active)
    end
  end
end
