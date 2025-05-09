FactoryBot.define do
  factory :library do
    name { Faker::Internet.unique.username }
    versions { Faker::Number.between(from: 1, to: 10).to_i.times.map { Faker::Number.number(digits: 3).to_s.split("").join(".") } }

    factory :gem do
      source { :remote_gem }
    end

    factory :github do
      source { :github }
      owner { Faker::Internet.unique.username }
      versions { Faker::Number.between(from: 1, to: 10).to_i.times.map { Faker::Internet.unique.username } }
    end

    factory :stdlib do
      source { :stdlib }
    end

    factory :featured do
      source { :featured }
    end
  end
end
