# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      # #region agent log
      Rails.logger.info("[DEBUG H1/H5] ActionCable connected user_id=#{current_user&.id} team_id=#{current_user&.team_id} pid=#{Process.pid}")
      # #endregion
    end

    private

    def find_verified_user
      token = token_from_cookie || request.params[:token].presence || token_from_authorization
      # #region agent log
      Rails.logger.info("[DEBUG H1] ActionCable auth attempt has_cookie=#{token_from_cookie.present?} has_param=#{request.params[:token].present?} has_header=#{token_from_authorization.present?}")
      # #endregion
      decoded = AuthService.decode(token)
      user = User.find_by(id: decoded[:user_id]) if decoded

      if user
        # #region agent log
        Rails.logger.info("[DEBUG H1] ActionCable auth SUCCESS user_id=#{user.id}")
        # #endregion
        user
      else
        # #region agent log
        Rails.logger.info("[DEBUG H1] ActionCable auth FAILED decoded=#{decoded.inspect}")
        # #endregion
        reject_unauthorized_connection
      end
    end

    def token_from_cookie
      cookies[:user_access_token]
    end

    def token_from_authorization
      request.headers['Authorization']&.split(' ')&.last
    end
  end
end
