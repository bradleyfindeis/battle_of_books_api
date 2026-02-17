class AuthService
  def self.secret_key
    if Rails.env.production?
      Rails.application.secret_key_base || raise('SECRET_KEY_BASE must be set in production')
    else
      Rails.application.secret_key_base || 'dev-secret-key'
    end
  end

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret_key)
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
