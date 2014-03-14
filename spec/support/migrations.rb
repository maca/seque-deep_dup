Sequel.migration do
  up do
    create_table :programs do
      primary_key :id
      String :name, null: false
    end

    create_table :courses do
      primary_key :id
      foreign_key :program_id, :programs
      String :name, null: false
      Date :starts
      Date :ends
    end

    create_table :assignments do
      primary_key :id
      foreign_key :course_id, :courses
      String :name, null: false
    end

    create_table :students do
      primary_key :id
      String :name, null: false
    end

    create_table :enrollments do
      foreign_key :student_id
      foreign_key :course_id
    end

    create_table :categories do
      primary_key :id
      String :name, null: false
    end

    create_table :course_categories do
      foreign_key :course_id, :courses
      foreign_key :category_id, :categories
    end
  end
end
