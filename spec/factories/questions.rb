FactoryGirl.define do
  factory :question do
    sequence(:text) { |n| "В каком году была космичесая одиссея #{n}?" }

    sequence(:level) { |n| n % 15}

    answer1 {"#{rand(2001)}"}
    answer2 {"#{rand(2001)}"}
    answer3 {"#{rand(2001)}"}
    answer4 {"#{rand(2001)}"}
  end
end
