Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.production?
      origins ENV.fetch('FRONTEND_URL', 'https://battle-of-books-frontend.onrender.com')
    else
      origins 'http://localhost:5173', 'http://localhost:3001', 'http://127.0.0.1:5173'
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['Authorization']
  end
end
