require 'swagger_helper'

RSpec.describe 'Admin Dashboard', type: :request do
  let(:admin) { create(:admin) }
  let(:Authorization) { "Bearer #{AdminAuthService.encode(admin_id: admin.id)}" }

  path '/admin/stats' do
    get 'Get stats' do
      tags 'Admin'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'stats' do
        schema '$ref' => '#/components/schemas/StatsResponse'
        run_test!
      end
    end
  end
end
