# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe User do
	before { @user = User.new( name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar" ) }

	subject { @user }

	it { should respond_to( :name ) }
	it { should respond_to( :email ) }
	it { should respond_to( :password_digest ) }
	it { should respond_to( :password ) }
	it { should respond_to( :password_confirmation ) }
	it { should respond_to( :remember_token ) }

	it { should be_valid }

	it { should respond_to( :authenticate ) }
	it { should respond_to( :admin ) }

	it { should respond_to( :microposts ) }

	it { should_not be_admin }


	describe "microposts associations" do
		before { @user.save }
		let!(:older_micropost) do
			FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago )
		end
		let!(:newer_micropost) do
			FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago )
		end

		it "should have the right microposts in right order" do
			@user.microposts.should == [newer_micropost, older_micropost]
		end

		it "should destroy associated microposts" do
			microposts = @user.microposts.dup
			@user.destroy
			microposts.should_not be_empty
			microposts.each do |m|
				Micropost.find_by_id( m.id ).should be_nil
			end
		end

		describe "status" do
			let(:unfollowed_post) do
				FactoryGirl.create(:micropost, user: FactoryGirl.create(:user) )
			end

			its(:feed) { should include( newer_micropost ) }
			its(:feed) { should include( older_micropost ) }
			its(:feed) { should_not include( unfollowed_post ) }
		end
	end

	describe "user attribute not-accesible" do
		it "should not allow to set user attribute" do
			expect { User.new(	name: "Example Nname", 
								email: "user@example.com", 
								password: "foobar", 
								password_confirmation: "foobar", 
								admin: true ) }.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
		end
	end

	describe "with admin attribute set to true" do
		before do
			@user.save!
			@user.toggle!(:admin)
		end

		it { should be_admin }
	end

	describe "remember_token" do
		before { @user.save }

		its(:remember_token) { should_not be_blank }
	end

	describe "with a password that's too short" do
		before { @user.password = @user.password_confirmation = "a" * 5 }
		it { should be_invalid }
	end

	describe "return value of authenticate method" do
		before{ @user.save }
		let( :found_user ){ User.find_by_email( @user.email ) }

		describe "valid with password" do
			it { should == found_user.authenticate( @user.password ) }
		end

		describe "invalid with password" do
			let( :user_for_invalid_password ) { found_user.authenticate( "invalid" ) }

			it { should_not == user_for_invalid_password }
			specify{ user_for_invalid_password.should be_false }
		end
	end

	describe "when password is not present" do
		before { @user.password = @user.password_confirmation = " " }
		it { should_not be_valid }
	end

	describe "when password doesn't match confirmation" do
		before { @user.password_confirmation = "mismatch" }
		it { should_not be_valid }
	end

	describe "when password confirmation is nil" do
		before { @user.password_confirmation = nil }
		it { should_not be_valid }
	end

	describe "when name is not present" do
		before { @user.name = " " }
		it { should_not be_valid }
	end

	describe "when name is too long" do
		before { @user.name = "a"*51 }
		it { should_not be_valid }
	end

	describe "email adress with mixed case" do
		let( :mixed_case_email ){ "Foo@ExAMPle.CoM" }

		it "should be saved as lower-case" do
			@user.email = mixed_case_email
			@user.save
			@user.reload.email.should == mixed_case_email.downcase
		end
	end

	describe "when email is not present" do
		before { @user.email = " " }
		it { should_not be_valid }
	end

	describe "when email format is invalid" do
		it "should be invalid" do
			adressess = %w[user user@foo,COM A_U_R.f.b.org exap@pl foo@bar@baz.org foo@bar+baz.pl]
			adressess.each do |invalid_adress|
				@user.email = invalid_adress
				@user.should_not be_valid
			end 
		end
	end

	describe "when email format is valid" do
		it "should be valid" do
			adressess = %w[user@foo.com user@foo.COM A_U-R@f.b.org foo.bar@az.org]
			adressess.each do |valid_adress|
				@user.email = valid_adress
				@user.should be_valid
			end
		end
	end

	describe "when email adress is already taken" do
		before do
			user_with_same_email = @user.dup
			user_with_same_email.email = @user.email.upcase
			user_with_same_email.save
		end

		it { should_not be_valid }
	end

end

