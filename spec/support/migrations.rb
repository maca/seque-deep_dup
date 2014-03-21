Sequel.migration do
  up do
    create_table :programs do
      primary_key :id
      String :name, null: false
    end

    create_table :courses do
      primary_key :id
      foreign_key :program_id, :programs, :on_delete => :restrict, :on_update => :restrict, :null => false
      String :name, null: false
      Date :starts
      Date :ends
    end

    create_table :assignments do
      primary_key :id
      foreign_key :course_id, :courses, :on_delete => :restrict, :on_update => :restrict, :null => false
      String :name, null: false
    end

    create_table :students do
      primary_key :id
      String :name, null: false
    end

    create_table :accounts do
      primary_key :id
      foreign_key :student_id, :students, :on_delete => :restrict, :on_update => :restrict, :null => false
      String :email, null: false
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
      foreign_key :course_id, :courses, :on_delete => :restrict, :on_update => :restrict, :null => false
      foreign_key :category_id, :categories, :on_delete => :restrict, :on_update => :restrict, :null => false
    end
  end
end
