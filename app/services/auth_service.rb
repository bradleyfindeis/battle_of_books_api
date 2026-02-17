class AuthService
  SECRET_KEY = if Rails.env.production?
                 Rails.application.credentials.secret_key_base || raise('SECRET_KEY_BASE must be set in production')
               else
                 Rails.application.credentials.secret_key_base || 'dev-secret-key'
               end

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
