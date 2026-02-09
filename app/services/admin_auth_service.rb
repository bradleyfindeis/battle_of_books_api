class AdminAuthService
  SECRET_KEY = (Rails.application.credentials.secret_key_base || 'dev-secret-key') + '_admin'

  def self.encode(payload, exp = 8.hours.from_now)
    payload[:exp] = exp.to_i
    payload[:type] = 'admin'
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    return nil unless decoded['type'] == 'admin'
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end
end
