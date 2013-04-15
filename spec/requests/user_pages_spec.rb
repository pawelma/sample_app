require 'spec_helper'

describe "UserPages" do
  
  subject { page }


  describe "progile page" do
  	let( :user ){ FactoryGirl.create( :user ) }
  	before { visit user_path( user ) }

  	it { should have_selector( 'h1', text: user.name ) }
  	it { should have_selector( 'title', text: full_title( user.name ) ) }
  end

  describe "Signup page" do
  	before { visit signup_path }

  	let( :submit ){ "Create my account" }

    it { should have_selector( 'h1', text: 'Sign up') }
    it { should have_selector( 'title', text: full_title('Sign up') ) }

    describe "with empty form" do
    	it "should not create a user" do
  			expect { click_button submit }.not_to change( User, :count )
  		end

      describe "after submission" do
        before{ click_button submit }
        
        it { should have_selector('title', text: full_title('Sign up') ) }
        it { should have_content('error') }
      end
  	end

  	describe "with properly filled form" do

      let(:email){ "user@example.com"}

  		before do
	  		fill_in "Name", with: "Example Name"
	  		fill_in "Email", with: email
	  		fill_in "Password", with: "foobar"
	  		fill_in "Password confirmation", with: "foobar"
	  	end

	  	it "should create user" do
  			expect { click_button submit }.to change( User, :count ).by(1)
  		end

      describe "after saving the user" do 
        before { click_button submit }

        let(:user) { User.find_by_email( email ) }

        it { should have_selector('title', text: full_title(user.name) ) }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
      end
  	end
  end

end
