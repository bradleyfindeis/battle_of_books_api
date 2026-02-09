require 'swagger_helper'

RSpec.describe 'Authentication', type: :request do
  path '/login' do
    post 'Login with PIN' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: { '$ref' => '#/components/schemas/LoginRequest' }

      response '200', 'success' do
        schema '$ref' => '#/components/schemas/AuthResponse'
        let(:team) { create(:team) }
        let(:user) { create(:user, team: team) }
        let(:body) { { username: user.username, team_id: team.id, pin_code: '1234' } }
        run_test!
      end

      response '401', 'invalid' do
        schema '$ref' => '#/components/schemas/Error'
        let(:body) { { username: 'x', team_id: 1, pin_code: '0000' } }
        run_test!
      end
    end
  end

  path '/register' do
    post 'Register team' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: { '$ref' => '#/components/schemas/RegisterRequest' }

      response '201', 'created' do
        let(:invite) { create(:invite_code) }
        let(:body) { { invite_code: invite.code, team_name: 'Test', username: 'lead', email: 't@t.com' } }
        run_test!
      end
    end
  end
end
