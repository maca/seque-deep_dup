FactoryGirl.define do
  factory :program do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Program #{num}" }
    
    trait :with_graph do
      courses_attributes { attributes_for_list(:course, 3, :with_graph) }
    end
  end

  factory :course do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Course #{num}" }

    trait :with_graph do
      assignments_attributes { attributes_for_list(:assignment, 3) }
      enrollments_attributes { attributes_for_list(:enrollment, 3, :with_graph) }
      categories_attributes  { attributes_for_list(:category, 3) }
    end
  end

  factory :assignment do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Assignment #{num}" }
  end

  factory :student do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Student #{num}" }

    trait :with_graph do
      profile_attributes { attributes_for(:profile) }
      account_attributes { attributes_for(:account) }
    end
  end

  factory :account do
    to_create { |instance| instance.save }
    sequence(:email) { |num| "student-#{num}@example.com" }
  end

  factory :profile do
    to_create { |instance| instance.save }
    sequence(:bio) { |num| "Student #{num}: lorem ipsum..." }
  end

  factory :enrollment do
    to_create { |instance| instance.save }

    trait :with_graph do
      student_attributes { attributes_for(:student, :with_graph) }
    end
  end

  factory :category do
    to_create { |instance| instance.save }
    sequence(:name) { |num| "Category #{num}" }
  end
end
