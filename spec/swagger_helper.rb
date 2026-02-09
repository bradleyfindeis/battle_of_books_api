require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s

  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: { title: 'Battle of the Books API', version: 'v1' },
      paths: {},
      servers: [{ url: 'http://localhost:3000' }],
      components: {
        securitySchemes: {
          bearer_auth: { type: :http, scheme: :bearer, bearerFormat: :JWT }
        },
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer }, username: { type: :string }, email: { type: :string, nullable: true },
              role: { type: :string, enum: %w[teammate team_lead] }, team_id: { type: :integer }, pin_reset_required: { type: :boolean }
            },
            required: %w[id username role team_id]
          },
          Team: {
            type: :object,
            properties: {
              id: { type: :integer }, name: { type: :string }, created_at: { type: :string, format: 'date-time' },
              teammate_count: { type: :integer }, invite_code: { type: :string, nullable: true },
              team_lead: { '$ref' => '#/components/schemas/User', nullable: true }
            },
            required: %w[id name teammate_count]
          },
          Book: {
            type: :object,
            properties: { id: { type: :integer }, title: { type: :string }, author: { type: :string, nullable: true }, team_id: { type: :integer } },
            required: %w[id title team_id]
          },
          BookAssignment: {
            type: :object,
            properties: {
              id: { type: :integer }, user_id: { type: :integer }, book_id: { type: :integer },
              status: { type: :string, enum: %w[assigned in_progress completed] }, progress_notes: { type: :string, nullable: true },
              book: { '$ref' => '#/components/schemas/Book', nullable: true }
            },
            required: %w[id user_id book_id status]
          },
          InviteCode: {
            type: :object,
            properties: {
              id: { type: :integer }, code: { type: :string }, name: { type: :string },
              max_uses: { type: :integer, nullable: true }, uses_count: { type: :integer },
              expires_at: { type: :string, format: 'date-time', nullable: true },
              active: { type: :boolean }, available: { type: :boolean }
            },
            required: %w[id code name uses_count active available]
          },
          LoginRequest: {
            type: :object,
            properties: { username: { type: :string }, team_id: { type: :integer }, pin_code: { type: :string } },
            required: %w[username team_id pin_code]
          },
          AdminLoginRequest: {
            type: :object,
            properties: { email: { type: :string }, password: { type: :string } },
            required: %w[email password]
          },
          RegisterRequest: {
            type: :object,
            properties: { invite_code: { type: :string }, team_name: { type: :string }, username: { type: :string }, email: { type: :string } },
            required: %w[invite_code team_name username email]
          },
          AuthResponse: {
            type: :object,
            properties: { token: { type: :string }, user: { '$ref' => '#/components/schemas/User' }, team: { '$ref' => '#/components/schemas/Team' }, pin_reset_required: { type: :boolean } },
            required: %w[token user]
          },
          AdminAuthResponse: {
            type: :object,
            properties: { token: { type: :string }, admin: { type: :object, properties: { id: { type: :integer }, email: { type: :string } } } },
            required: %w[token admin]
          },
          Error: { type: :object, properties: { error: { type: :string } }, required: %w[error] },
          StatsResponse: {
            type: :object,
            properties: {
              total_teams: { type: :integer }, total_users: { type: :integer }, total_assignments: { type: :integer },
              assignments_by_status: { type: :object, properties: { assigned: { type: :integer }, in_progress: { type: :integer }, completed: { type: :integer } } }
            }
          }
        }
      }
    }
  }
  config.openapi_format = :yaml
end
