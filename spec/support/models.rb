Sequel::Model.plugin :nested_attributes
Sequel::Model.plugin :auto_validations

class Program < Sequel::Model
  one_to_many :courses

  nested_attributes :courses
end

class Course < Sequel::Model
  many_to_one  :program
  one_to_many  :assignments
  one_to_many  :enrollments

  many_to_many :categories, join_table: :course_categories
  
  nested_attributes :assignments
  nested_attributes :enrollments
  nested_attributes :categories
end

class Assignment < Sequel::Model
  many_to_one :course
end

class Enrollment < Sequel::Model
  unrestrict_primary_key
  set_primary_key [:student_id, :course_id]
  many_to_one :student
  many_to_one :course

  nested_attributes :student
end

class Student < Sequel::Model
  one_to_many :enrollments
  one_to_one  :account
  one_to_one  :profile

  nested_attributes :account
  nested_attributes :profile
end

class Account < Sequel::Model
  many_to_one :student
end

class Profile < Sequel::Model
  set_primary_key :student_id  
  many_to_one :student
end

class Category < Sequel::Model
  many_to_many :courses, join_table: :course_categories
end
