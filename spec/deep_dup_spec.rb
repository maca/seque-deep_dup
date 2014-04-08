require 'spec_helper'

describe Sequel::Plugins::DeepDup do
  let(:program)         { create :program, :name =>'CS' }
  let(:program_copy)    { program.deep_dup }
  let(:course)          { create :course, :name => 'Ruby', :program => program }
  let(:course_copy)     { course.deep_dup }
  let(:student)         { create :student, :name => 'Macario' }
  let(:student_copy)    { student.deep_dup }
  let(:enrollment)      { create :enrollment, :student_id => student.id, :course_id => course.id }
  let(:enrollment_copy) { enrollment.deep_dup }

  context 'no explicit assoc graph is passed' do
    before do
      enable_deep_dup_for Program, Course, Enrollment, Student, Profile, Account
    end

    describe 'duplication plain record' do
      context 'with regular pk' do
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
        3.times { |num| program.add_course :name => "Course #{num}" }
      end

      context 'with no nesting' do
        it { program_copy.should have(3).courses }
        it { program_copy.courses.map(&:pk).should be_none }
        it { expect { program_copy.save }.to change{ Course.count }.to(6) }
      end

      context 'with nesting' do
        before do
          program.courses.each do |course|
            3.times { |num| course.add_assignment :name => "Assignment #{num}" }
          end
        end

        it { program_copy.should have(3).courses }
        it { program_copy.courses.first.should have(3).assignments }
        it { expect { program_copy.save }.to change{ Course.count }.to(6) }
        it { expect { program_copy.save }.to change{ Assignment.count }.to(18) }
      end
    end

    describe 'reasociating to many to many' do
      context 'when has many to many children' do
        before do
          3.times { |num| course.add_category :name => "Category #{num}" }
        end

        it { course_copy.should have(3).categories }
        it { course_copy.categories.should == course.categories }
        it { expect { course_copy.save }.not_to change{ Category.count } }
      end

      context 'when child has many to many children' do
        before do
          3.times { |num| program.add_course :name => "Course #{num}" }
          program.courses.each do |course|
            3.times { |num| course.add_category :name => "Category #{num}" }
          end
        end

        it { program_copy.should have(3).courses }
        it { program_copy.courses.first.should have(3).categories }
        it { program_copy.courses.last.should have(3).categories }
        it { expect { program_copy.save }.not_to change{ Category.count } }
      end
    end

    describe 'duplicating record with one to one' do
      context 'when regular fk' do
        before { student.account = Account.new(:email => 'mail@makarius.me') }
        it { student_copy.account.pk.should be_nil }
        it { student_copy.account.email.should == 'mail@makarius.me' }
        it { expect { student_copy.save }.to change { Account.count }.to(2) }
      end

      context 'when foreign key is also pk' do
        before do
          student.profile = create(:profile, :bio => 'likes sequel, rides bycicle', :student => student)
        end
        it { student_copy.profile.pk.should be_nil }
        it { student_copy.profile.bio.should == 'likes sequel, rides bycicle' }
        it { expect { student_copy.save }.to change { Profile.count }.to(2) }
      end
    end

    describe 'omits many to one association' do
      context 'when regular fk' do
        let(:account)      { create(:account, :email => 'mail@makarius.me', :student => student) }
        let(:account_copy) { account.deep_dup }
        it { account_copy.student_id.should be_nil }
        it { account_copy.student.should be_nil }
        it { account_copy.email.should == 'mail@makarius.me' }
      end

      context 'when foreign key is also pk' do
        let(:profile)      { create(:profile, :bio => 'likes sequel, rides bycicle', :student => student) }
        let(:profile_copy) { profile.deep_dup }
        it { profile_copy.student.should be_nil }
        it { profile_copy.student_id.should be_nil }
        it { profile_copy.bio.should == 'likes sequel, rides bycicle' }
      end
    end
  end

  describe 'restrictions' do
    before do
      Program.plugin :deep_dup
      Course.plugin :deep_dup
    end

    let!(:program) { create :program, :with_graph }


    describe 'validate graph' do
      it { Course.count.should be 3 }
      it { Assignment.count.should be 9 }
      it { Enrollment.count.should be 9 }
      it { Student.count.should be 9 }
      it { Account.count.should be 9 }
      it { Profile.count.should be 9 }
      it { Category.count.should be 9 }
    end

    describe 'restricts to children' do
      let(:program_copy) { program.deep_dup :courses }
      it { expect { program_copy.save }.to change{ Course.count }.by(3) }
      it { expect { program_copy.save }.not_to change{ Enrollment.count } }
    end

    describe 'restricts to children of children' do
      let(:program_copy) { program.deep_dup :courses => :assignments }
      it { expect { program_copy.save }.to change{ Course.count }.by(3) }
      it { expect { program_copy.save }.to change{ Assignment.count }.by(9) }
      it { expect { program_copy.save }.not_to change{ Enrollment.count } }
    end

    describe 'restricts to graph' do
      let(:program_copy) { program.deep_dup :courses => [:assignments, :categories, {:enrollments => {:student => [:profile, :account]}}] }
      it { expect { program_copy.save }.to change { Course.count }.by(3) }
      it { expect { program_copy.save }.to change { Assignment.count }.by(9) }
      it { expect { program_copy.save }.to change { Enrollment.count }.by(9) }
      it { expect { program_copy.save }.to change { Student.count }.by(9) }
      it { expect { program_copy.save }.to change { Account.count }.by(9) }
      it { expect { program_copy.save }.to change { Profile.count }.by(9) }
      it { expect { program_copy.save }.to change { DB[:course_categories].count }.by(9) }
      it { expect { program_copy.save }.not_to change { Category.count } }
    end

    describe 'allows different graphs for same record with different graph format' do
      let(:course) { program.courses.first }
      
      let(:course_copy) { course.deep_dup({:categories => [], :enrollments => {:student => [:profile, :account]}}, :assignments) }
      it { expect { course_copy.save }.to change { Course.count }.by(1) }
      it { expect { course_copy.save }.to change { Assignment.count }.by(3) }
      it { expect { course_copy.save }.to change { Enrollment.count }.by(3) }
      it { expect { course_copy.save }.to change { Student.count }.by(3) }
      it { expect { course_copy.save }.to change { Account.count }.by(3) }
      it { expect { course_copy.save }.to change { Profile.count }.by(3) }
      it { expect { course_copy.save }.to change { DB[:course_categories].count }.by(3) }
      it { expect { course_copy.save }.not_to change { Category.count } }
    end

    describe 'parsing graph' do
      let(:dupper) { Sequel::Plugins::DeepDup::DeepDupper.new(nil) }

      # it 'maps symbols' do
      #   parsed = dupper.parse_graph( [:course, :assignments, :categories] )
      #   parsed.should == [[:course], [:assignments], [:categories]]
      # end

      # it 'maps symbols followed by hash' do
      #   parsed = dupper.parse_graph( [:course, {:assignments => :categories}] )
      #   parsed.should == [[:course], [:assignments, :categories]]
      # end

      # it 'maps hash with several keys' do
      #   parsed = dupper.parse_graph( :assignments => [], :categories => [], :enrollments => [:student] )
      #   parsed.should == [[:assignments], [:categories], [:enrollments, :student]]
      # end

      it 'maps array of symbol and hashes' do
        parsed = dupper.parse_graph( [:assignments, {:categories => [], :enrollments => [:student]}] )
        parsed.should == [[:assignments], [:categories], [:enrollments, :student]]
      end

      it 'maps array of symbol and hashes with nested assoc array' do
        parsed = dupper.parse_graph( [:assignments, {:enrollments => [:student, :course]}] )
        parsed.should == [[:assignments], [:enrollments, [:student, :course]]]
      end

      # it 'maps nested hashes' do
      #   parsed = dupper.parse_graph([{:courses=>[:assignments, :categories, {:enrollments=>{:student=>[:profile, :account]}}]}])
      #   parsed.should == [[:courses, :assignments, :categories, {:enrollments=>{:student=>[:profile, :account]}}]]
      # end
    end


    it 'raises exception when association present in graph is not defined in model' do
      expect { program.deep_dup :potatoes }.to raise_error(Sequel::Error)
    end
  end
end
