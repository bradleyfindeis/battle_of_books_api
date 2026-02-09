require 'swagger_helper'

RSpec.describe 'Admin Invite Codes', type: :request do
  let(:admin) { create(:admin) }
  let(:Authorization) { "Bearer #{AdminAuthService.encode(admin_id: admin.id)}" }

  path '/admin/invite_codes' do
    get 'List codes' do
      tags 'Admin'
      security [bearer_auth: []]
      produces 'application/json'

      response '200', 'list' do
        schema type: :array, items: { '$ref' => '#/components/schemas/InviteCode' }
        run_test!
      end
    end

    post 'Create code' do
      tags 'Admin'
      security [bearer_auth: []]
      consumes 'application/json'
      parameter name: :body, in: :body, schema: { type: :object, properties: { name: { type: :string } }, required: ['name'] }

      response '201', 'created' do
        schema '$ref' => '#/components/schemas/InviteCode'
        let(:body) { { name: 'Test School' } }
        run_test!
      end
    end
  end
end
