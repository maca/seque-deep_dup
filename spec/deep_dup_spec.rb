require 'spec_helper'

describe Sequel::Plugins::DeepDup do
  let(:program)         { Program.create name: 'CS' }
  let(:program_copy)    { program.deep_dup }
  let(:course)          { Course.create name: 'Ruby' }
  let(:course_copy)     { course.deep_dup }
  let(:student)         { Student.create name: 'Macario' }
  let(:enrollment)      { Enrollment.create }
  let(:enrollment_copy) { enrollment.deep_dup }

  describe 'duplicating plain record' do
    before do
      Program.plugin :deep_dup
      Enrollment.plugin :deep_dup
    end

    it { program_copy.name.should == 'CS' }
    it { program_copy.pk.should be_nil } 
    it { program_copy.should be_new } 
    it { enrollment_copy.pk.should == [nil, nil] } 
    it { enrollment_copy.should be_new }
  end

  describe 'duplicating record with a one to many association' do
    before do
      Program.plugin :deep_dup
      3.times { |num| program.add_course name: "Course #{num}" }
    end

    it { program_copy.should have(3).courses }
    it { program_copy.courses.map(&:pk).should be_none }
    it { expect { program_copy.save }.to change{ Course.count }.by(3) }
  end

  describe 'duplicating record with a many to many association' do
    before do
      Course.plugin :deep_dup
      3.times { |num| course.add_category name: "Category #{num}" }
    end

    it { course_copy.should have(3).categories }
    it { course_copy.categories.should == course.categories }
    it { expect { course_copy.save }.not_to change{ Category.count } }
  end

  describe 'duplicating record with nested many to many' do
    before do
      Program.plugin :deep_dup
      3.times { |num| program.add_course name: "Course #{num}" }

      program.courses.each do |course|
        3.times { |num| course.add_assignment name: "Assignment #{num}" }
      end
    end

    it { program_copy.should have(3).courses }
    it { program_copy.courses.first.should have(3).assignments }
    it { expect { program_copy.save }.to change{ Course.count }.by(3) }
    it { expect { program_copy.save }.to change{ Assignment.count }.by(9) }
  end

  describe 'duplicating record with circular association graph' do
    before do
      Program.plugin :deep_dup
      Course.many_to_one  :program
      3.times { |num| program.add_course name: "Course #{num}" }
    end

    it 'should not raise stack level too deep' do
      expect { program_copy }.not_to raise_error
    end
  end
end
