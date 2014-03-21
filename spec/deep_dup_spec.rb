require 'spec_helper'

describe Sequel::Plugins::DeepDup do
  let(:program)         { Program.create name: 'CS' }
  let(:program_copy)    { program.deep_dup }
  let(:course)          { Course.create name: 'Ruby' }

  let(:course_copy)     { course.deep_dup }
  let(:student)         { Student.create name: 'Macario' }
  let(:student_copy)    { student.deep_dup }
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

  describe 'duplicating record with one to one' do
    before do
      Student.plugin :deep_dup
      student.account = Account.create(email: 'mail@makarius.me')
    end

    it { student_copy.account.pk.should be_nil }
    it { student_copy.account.email.should == 'mail@makarius.me' }
    it { expect { student_copy.save }.to change { Account.count }.by(1) }
  end

  describe 'duplicating record with many to one association' do
    before do
      Account.plugin :deep_dup
      student.account = Account.create(email: 'mail@makarius.me')
    end

    let(:account_copy) { student.account.deep_dup }

    it { account_copy.student.pk.should be_nil }
    it { account_copy.student.name.should == 'Macario' }
    it { expect { account_copy.save }.to change { Student.count }.by(1) }
  end
end
