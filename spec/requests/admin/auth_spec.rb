require 'swagger_helper'

RSpec.describe 'Admin Auth', type: :request do
  path '/admin/login' do
    post 'Admin login' do
      tags 'Admin'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: { '$ref' => '#/components/schemas/AdminLoginRequest' }

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/AdminAuthResponse'
        let(:admin) { create(:admin) }
        let(:body) { { email: admin.email, password: 'password123' } }
        run_test!
      end
    end
  end
end
