require 'spec_helper'

describe Sequel::Plugins::DeepDup do
  let(:program)         { Program.create name: 'CS' }
  let(:program_copy)    { program.deep_dup }
  let(:course)          { Course.create name: 'Ruby', program: program }
  let(:course_copy)     { course.deep_dup }
  let(:student)         { Student.create name: 'Macario' }
  let(:student_copy)    { student.deep_dup }
  let(:enrollment)      { Enrollment.create(student_id: student.id, course_id: course.id) }
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
    it { expect { program_copy.save }.to change{ Course.count }.to(6) }
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

  describe 'duplicating record with nested many to one' do
    before do
      Program.plugin :deep_dup
      3.times { |num| program.add_course name: "Course #{num}" }

      program.courses.each do |course|
        3.times { |num| course.add_assignment name: "Assignment #{num}" }
      end
    end

    it { program_copy.should have(3).courses }
    it { program_copy.courses.first.should have(3).assignments }
    it { expect { program_copy.save }.to change{ Course.count }.to(6) }
    it { expect { program_copy.save }.to change{ Assignment.count }.to(18) }
  end

  describe 'duplicating record with a many to many association after a many to one' do
    before do
      Program.plugin :deep_dup
      3.times { |num| program.add_course name: "Course #{num}" }
      program.courses.each do |course|
        3.times { |num| course.add_category name: "Category #{num}" }
      end
    end
    
    it { program_copy.should have(3).courses }
    it { program_copy.courses.first.should have(3).categories }
    it { program_copy.courses.last.should have(3).categories }
    it { expect { program_copy.save }.not_to change{ Category.count } }
  end

  describe 'duplicating record with one to one' do
    before do
      Student.plugin :deep_dup
      student.account = Account.new(email: 'mail@makarius.me')
    end

    it { student_copy.account.pk.should be_nil }
    it { student_copy.account.email.should == 'mail@makarius.me' }
    it { expect { student_copy.save }.to change { Account.count }.to(2) }
  end

  describe 'duplicating record with many to one association' do
    before do
      Account.plugin :deep_dup
    end

    let(:account)      { Account.create(email: 'mail@makarius.me', student: student) }
    let(:account_copy) { account.deep_dup }

    it { account_copy.student.pk.should be_nil }
    it { account_copy.student.name.should == 'Macario' }
    it { expect { account_copy.save }.to change { Student.count }.to(2) }
  end

  describe 'duplicating record with one to one when foreign key is pk' do
    before do
      Student.plugin :deep_dup
      student.profile = Profile.create(bio: 'likes sequel, rides bycicle', student: student)
    end

    it { student_copy.profile.pk.should be_nil }
    it { student_copy.profile.bio.should == 'likes sequel, rides bycicle' }
    it { expect { student_copy.save }.to change { Profile.count }.to(2) }
  end

  describe 'duplicating record with many to one association when foreign key is pk' do
    before do
      Profile.plugin :deep_dup
    end

    let(:profile)      { Profile.create(bio: 'likes sequel, rides bycicle', student: student) }
    let(:profile_copy) { profile.deep_dup }

    it { profile_copy.student.pk.should be_nil }
    it { profile_copy.student.name.should == 'Macario' }
    it { expect { profile_copy.save }.to change { Student.count }.to(2) }
  end
end
