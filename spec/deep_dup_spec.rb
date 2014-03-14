require 'spec_helper'

describe Sequel::Plugins::DeepDup do
  let(:program)         { create :program, name: 'CS' }
  let(:program_copy)    { program.deep_dup }
  let(:course)          { create :course, name: 'Ruby', starts: Date.today, ends: Date.today + 30 }
  let(:course_copy)     { course.deep_dup }
  let(:student)         { create :student }
  let(:enrollment)      { create :enrollment, student: student, course: course }
  let(:enrollment_copy) { enrollment.deep_dup }

  describe 'attribute duplication' do
    before do
      Course.plugin :deep_dup
      Enrollment.plugin :deep_dup
    end

    it 'clones attributes' do
      course_copy.name.should   == 'Ruby'
      course_copy.starts.should == Date.today
      course_copy.ends.should   == Date.today + 30
    end
    
    it 'sets a new primary key for the copy' do
      course_copy.id.should_not == course.id
    end

    it 'sets a new composite primary key for copy' do
      enrollment_copy.pk.should_not == enrollment.id
    end
  end

  describe 'association duplication' do
    let(:courses) { 3.times.map { |num| attributes_for :course, name: "Course #{num}" } }

    before do
      Program.plugin :deep_dup
      courses.each { |course| program.add_course course }
    end

    it { expect { program_copy }.to change { Course.count }.by(3) }
    it { program_copy.should have(3).courses }

    it 'has different courses for copy than for the original' do
      orig_course_ids = program.courses.map(&:id) 
      copy_course_ids = program_copy.courses.map(&:id)
      all_course_ids  = orig_course_ids | copy_course_ids

      all_course_ids.should have(6).items
    end
  end
end
