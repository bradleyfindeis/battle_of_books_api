FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { 'password123' }
  end

  factory :invite_code do
    sequence(:name) { |n| "School #{n}" }
    admin
  end

  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    invite_code
  end

  factory :user do
    sequence(:username) { |n| "user#{n}" }
    team
    role { :tate }
    pin_reset_required { true }
    after(:build) { |user| user.pin_code = '1234' }

    trait :team_lead do
      role { :team_lead }
      sequence(:email) { |n| "lead#{n}@example.com" }
      pin_reset_required { false }
    end
  end

  factory :book do
    sequence(:title) { |n| "Book #{n}" }
    author { "Author" }
    team
  end

  factory :book_assignment do
    user
    book { association :book, team: user.team }
    assigned_by { association :user, :team_lead, team: user.team }
    status { :assigned }
  end
end
