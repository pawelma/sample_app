require 'spec_helper'

describe "UserPages" do
  
  subject { page }

  describe "index" do
    before do
      sign_in FactoryGirl.create(:user)
      FactoryGirl.create(:user, name: "Ben", email: "ben@example.com")
      FactoryGirl.create(:user, name: "Bob", email: "bob@example.com")
      visit users_path
    end

    it { should have_selector 'title', text: 'All users' }
    it { should have_selector 'h1', text: 'All users' }

    describe "delete links" do
      let(:admin) { FactoryGirl.create(:admin) }

      it { should_not have_link 'delete' }

      describe "as a non-admin user" do
        let(:user) { FactoryGirl.create(:user) }
        let(:non_admin) { FactoryGirl.create(:user) }

        before do
          click_link "Sign out"
          sign_in non_admin 
        end

        describe "submitting a delete action to Users#destroy" do
          before { delete user_path( user ) }
          specify { response.should redirect_to root_path }
        end
      end

      describe "as an admin user" do
        before do
          click_link "Sign out"
          sign_in admin
          visit users_path
        end

        it{ should have_link( 'delete', href: user_path( User.first ) ) }
        
        it "should be able to delete another user" do
          expect { click_link('delete') }.to change(User, :count).by(-1)
        end

        it { should_not have_link('delete', href: user_path(admin) ) }
        
        it "should not be able to delete himself" do
          expect { delete user_path( admin ) }.not_to change( User, :count )
        end
      end
    end

    describe "pagination" do

      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all) { User.delete_all }

      it { should have_selector 'div.pagination' }

      it "should list each user" do
        User.paginate(page: 1) do |user|
          page.should have_selector 'li', text: user.name
        end
      end
    end

  end

  describe "profile page" do
  	let( :user ){ FactoryGirl.create( :user ) }
    let!(:m1) { FactoryGirl.create( :micropost, user: user, content: "Foo" ) }
    let!(:m2) { FactoryGirl.create( :micropost, user: user, content: "Bar" ) }

  	before { visit user_path( user ) }

  	it { should have_selector( 'h1', text: user.name ) }
  	it { should have_selector( 'title', text: full_title( user.name ) ) }

    describe "microposts" do
      it { should have_content m1.content }
      it { should have_content m2.content }
      it { should have_content user.microposts.count }
    end
  end

  describe "Edit" do

    let( :user ){ FactoryGirl.create( :user ) }
    before do
      sign_in user
      visit edit_user_path( user ) 
    end

    describe "page" do
      it { should have_selector 'title', text: 'Edit user' }
      it { should have_selector 'h1', text: 'Update your profile' }
      it { should have_link 'change', href: 'http://gravatar.com/emails' }
    end

    describe "with invalid form" do
      before { click_button "Save changes" }

      it { should have_content 'error' }
    end

    describe "with valid form" do
      let( :new_name ) { "New Name" }
      let( :new_email ) { "new@example.com" }

      before do
        fill_in "Name",             with: new_name
        fill_in "Email",            with: new_email
        fill_in "Password",         with: user.password
        fill_in "Confirm Password", with: user.password

        click_button "Save changes"
      end

      it { should have_selector( 'title', text: new_name ) }
      it { should have_selector( 'div.alert.alert-success' ) }
      it { should have_link( 'Sign out') }
      specify{ user.reload.name.should == new_name }
      specify{ user.reload.email.should == new_email }
    end

  end

  describe "Signup page" do
  	before { visit signup_path }

  	let( :submit ){ "Create my account" }

    it { should have_selector( 'h1', text: 'Sign up') }
    it { should have_selector( 'title', text: full_title('Sign up') ) }

    describe "by signed in user" do 
      let( :user ) { FactoryGirl.create( :user ) }

      before do 
        sign_in user
        visit signup_path
      end

      it { should_not have_selector 'title', text: full_title('Sign up') }

      describe "prevent post new data" do
        before { post signup_path }
        specify { response.should redirect_to( root_path ) }
      end
    end

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
	  		fill_in "Confirm Password", with: "foobar"
	  	end

	  	it "should create user" do
  			expect { click_button submit }.to change( User, :count ).by(1)
  		end

      describe "after saving the user" do 
        before { click_button submit }

        let(:user) { User.find_by_email( email ) }

        it { should have_selector('title', text: full_title(user.name) ) }
        it { should have_selector('div.alert.alert-success', text: 'Welcome') }
        it { should have_link('Sign out') }

        describe "followed by signout" do
          before { click_link "Sign out" }
          it { should have_link('Sign in') }
        end
      end
  	end
  end

end
