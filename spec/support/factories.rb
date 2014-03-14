FactoryGirl.define do
  factory :program do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Program #{num}" }
  end

  factory :course do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Course #{num}" }
  end

  factory :assignment do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Assignment #{num}" }
  end

  factory :student do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Student #{num}" }
  end

  factory :enrollment do
    to_create { |instance| instance.save }
  end

  factory :category do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Category #{num}" }
  end
end
