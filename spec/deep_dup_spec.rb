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

  before do
    enable_deep_dup_for Program, Course, Enrollment, Student, Profile, Account
  end

  context 'no explicit assoc graph is passed' do
    describe 'duplication plain record' do
      context 'with single pk' do
        it { program_copy.name.should == 'CS' }
        it { program_copy.pk.should be_nil } 
      end

      context 'with composite pks' do
        it { program_copy.should be_new } 
        it { enrollment_copy.pk.should == [nil, nil] } 
        it { enrollment_copy.should be_new }
      end
    end

    describe 'duplicating one to many children' do
      before do
        3.times { |num| program.add_course name: "Course #{num}" }
      end

      context 'with no nesting' do
        it { program_copy.should have(3).courses }
        it { program_copy.courses.map(&:pk).should be_none }
        it { expect { program_copy.save }.to change{ Course.count }.to(6) }
      end

      context 'with nesting' do
        before do
          program.courses.each do |course|
            3.times { |num| course.add_assignment name: "Assignment #{num}" }
          end
        end

        it { program_copy.should have(3).courses }
        it { program_copy.courses.first.should have(3).assignments }
        it { expect { program_copy.save }.to change{ Course.count }.to(6) }
        it { expect { program_copy.save }.to change{ Assignment.count }.to(18) }
      end
    end

    describe 'reasociating to many to many' do
      context 'has many to many children' do
        before do
          3.times { |num| course.add_category name: "Category #{num}" }
        end

        it { course_copy.should have(3).categories }
        it { course_copy.categories.should == course.categories }
        it { expect { course_copy.save }.not_to change{ Category.count } }
      end

      describe 'child has many to many children' do
        before do
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
    end

    describe 'duplicating record with one to one' do
      context 'regular fk' do
        before { student.account = Account.new(email: 'mail@makarius.me') }
        it { student_copy.account.pk.should be_nil }
        it { student_copy.account.email.should == 'mail@makarius.me' }
        it { expect { student_copy.save }.to change { Account.count }.to(2) }
      end

      describe 'foreign key is also pk' do
        before do
          student.profile = Profile.create(bio: 'likes sequel, rides bycicle', student: student)
        end
        it { student_copy.profile.pk.should be_nil }
        it { student_copy.profile.bio.should == 'likes sequel, rides bycicle' }
        it { expect { student_copy.save }.to change { Profile.count }.to(2) }
      end
    end

    describe 'omits many to one association' do
      describe 'regular fk' do
        let(:account)      { Account.create(email: 'mail@makarius.me', student: student) }
        let(:account_copy) { account.deep_dup }
        it { account_copy.student_id.should be_nil }
        it { account_copy.student.should be_nil }
        it { account_copy.email.should == 'mail@makarius.me' }
      end

      describe 'foreign key is also pk' do
        let(:profile)      { Profile.create(bio: 'likes sequel, rides bycicle', student: student) }
        let(:profile_copy) { profile.deep_dup }
        it { profile_copy.student.should be_nil }
        it { profile_copy.student_id.should be_nil }
        it { profile_copy.bio.should == 'likes sequel, rides bycicle' }
      end
    end
  end
end
