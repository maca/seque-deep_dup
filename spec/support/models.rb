class Program < Sequel::Model
  one_to_many :courses
end

class Course < Sequel::Model
  many_to_one  :program
  one_to_many  :assignments
  many_to_many :categories, join_table: :course_categories
end

class Assignment < Sequel::Model
  many_to_one :course
end

class Student < Sequel::Model
  one_to_many :enrollments
  one_to_one  :account
end

class Account < Sequel::Model
  many_to_one :student
end

class Enrollment < Sequel::Model
  set_primary_key [:student_id, :course_id]
  many_to_one :student
  many_to_one :course
end

class Category < Sequel::Model
  many_to_many :courses, join_table: :course_categories
end
