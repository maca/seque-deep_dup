require 'spec_helper'

describe Sequel::Plugins::DeepDup do
  let(:program)         { create :program, name: 'CS' }
  let(:program_copy)    { program.deep_dup }
  let(:course)          { create :course, name: 'Ruby', starts: Date.today, ends: Date.today + 30 }
  let(:course_copy)     { course.deep_dup }
  let(:student)         { create :student }
  let(:enrollment)      { create :enrollment }
  let(:enrollment_copy) { enrollment.deep_dup }

  describe 'cloning a plain record' do
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

  describe 'clonig a record with a one to many association' do
    before do
      Program.plugin :deep_dup
      3.times { |num| program.add_course name: "Course #{num}" }
    end

    it { program_copy.should have(3).courses }
    it { program_copy.courses.map(&:pk).should be_none }
    it { expect { program_copy.save }.to change{ Course.count }.by(3) }
  end
end
