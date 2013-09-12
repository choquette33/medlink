#### UTILITY METHODS ###

def create_visitor
  email    = "joe.doe@gmail.com"
  password = "please123"
  @visitor ||= { :first_name => "Joe", :last_name => "Doe", 
    :email => email,
    :password => password, :password_confirmation => password }
end

def create_user role: :user, name: "joe", country: nil
  email    = "#{name}.doe@gmail.com"
  password = "please123"
  pcv_id = Random.new.rand(10000000..99999999).to_s
  user_country = country || FactoryGirl.create(:country)
  @user = FactoryGirl.create(role.to_sym, 
    :email => email, :password => password, :password_confirmation => password,
    :country => user_country, :city => "Roswell",
    :first_name => name, :last_name => "Doe", :pcv_id => pcv_id)
end

def set_role(role)
  #ADMIN: , :role => 'admin'
  #PCV:   , :role => 'pcv'
  #PCMO:  , :role => 'pcmo'
  #WAS: @user = { :role => role }
  if @user
    @user.update_attributes(role: role)
    @user.save
  else
    @user = User.new(role: role)
  end
end

def sign_in
  visit '/users/sign_in'
  fill_in "email@email.com", :with => @visitor[:email]
  fill_in "Password", :with => @visitor[:password]
  click_button "Sign in"
end

def delete_user
  @user ||= User.where('email' => @visitor[:email]).first
  @user.destroy unless @user.nil?
end

### GIVEN ############################################################

Given /^I am not logged in$/ do
  visit '/'
end

Given /^I exist as a user$/ do
  create_user
end

Given /^the default user exists$/ do
  create_visitor
  create_user
end

Given(/^I am (a|an|the) "(.*?)"$/) do |_, role|
  set_role(role)
end

Given /^I do not exist as a user$/ do
  create_visitor
  delete_user
end

Given /^I am logged in$/ do
  create_user
  sign_in
end

Given /^I am logged in as (a|an|the) (\w+)$/ do |_, role|
   create_user role: role
   create_visitor
   sign_in
end

Given(/^I am logged in as (a|an|the) (\w+) of (\w+)$/) do |_, role, country|
   create_user role: role, country: Country.find_by_name(country)
   create_visitor
   sign_in
end

When /^I sign in with valid credentials$/ do
  create_visitor
  sign_in
end

When /^I sign out$/ do
  click_link "Sign Out"
end


When /^I return to the site$/ do
  visit '/'
end

Then (/^I should be signed in as "(.*?)"$/) do |role|
  if role == "admin"
    expect(current_url).to eq("http://www.example.com/admin/users/new")
  elsif role == "pcmo"
    expect(current_url).to eq("http://www.example.com/orders/manage")
  else # PCV
    expect(current_url).to eq("http://www.example.com/orders")
  end
end

Then /^I should be signed in$/ do
  expect(current_url).to eq("http://www.example.com/orders")
end

Then /^I see a successful sign in message$/ do
  page.should have_selector ".alert", text: "Signed in successfully."
end

Then /^I should be signed out$/ do
  find("h3", :text => "Sign in").visible?
end

Given(/^that pcv "(.*?)" exists$/) do |name|
  create_user role: :user, name: name
end

Given(/^that the following pcvs exist:$/) do |users|
  users.hashes.each do |user|
    FactoryGirl.create :user, first_name: user['name'],
      pcv_id: user['pcv_id'], country: Country.find_by_name(user['country'])
  end
end

Then /^I should see a signed out message$/ do
  page.should have_content "Signed out successfully."
end

When(/^I sign in with a blank password$/) do
  @visitor = @visitor.merge(:password => "")
  sign_in
end

Then /^I see an invalid login message$/ do
  page.should have_selector ".alert", text: "Invalid email or password."
end

# E1
When(/^I sign in with a invalid email$/) do
  create_visitor
  @visitor = @visitor.merge(:email => "notanemail")
  sign_in
end

# E2
When /^I sign in with a unknown email$/ do
  @visitor = @visitor.merge(:email => "unknown@example.com")
  sign_in
end

# K
When(/^I sign in with a invalid password$/) do
  @visitor = @visitor.merge(:password => "123")
  sign_in
end

# E1 ERROR MSG
Then /^I see an invalid email message$/ do
  #FIXME:  (#114#: E1)
  #page.should have_selector ".alert", text: "Email Invalid:
  #    The email you specified is invalid. Please check the spelling,
  #    formatting and that it is an active address.
  page.should have_selector ".alert", text: "Invalid email or password."
end

# E2 ERROR MSG (unregistered)
Then /^I see an unregistered email message$/ do
  #FIXME: (#114#: E2)
  #page.should have_selector ".alert", text: "The email you entered
  #    is not on file. Please check the spelling and formatting
  #    before re-entering the address.
  page.should have_selector ".alert", text: "Invalid email or password."
end

Then /^I see an unknown email message$/ do
  #FIXME: (#114#: E2)
  #page.should have_selector ".alert", text: "The email you entered
  #    is not on file. Please check the spelling and formatting
  #    before re-entering the address.
  page.should have_selector ".alert", text: "Invalid email or password."
end

# K ERROR MSG
Then(/^I see an invalid password message$/) do
  #FIXME:  (#114#: K)
  #page.should have_selector ".alert", text: "Invalid Password: the
  #    Password you entered is not valid. Please re-enter your password
  #    or contact your administrator via email for more help."
  page.should have_selector ".alert", text: "Invalid email or password."
end

Then(/^I see an blank password message$/) do
  #FIXME: (#114#: K)
  #page.should have_selector ".alert", text: "Invalid Password: the
  #    Password you entered is not valid. Please re-enter your password
  #    or contact your administrator via email for more help."
  page.should have_selector ".alert", text: "Invalid email or password."
end

When(/^I ask for a forgotten password$/) do
  visit 'http://localhost:3000/users/password/new'
end

When(/^I give an invalid email$/) do
  delete_user ; create_user
  fill_in "email@email.com", :with => "notanemail" # BAD
  fill_in "PCV ID", :with => @user[:pcv_id] # GOOD
  click_button "Submit"
end

Then(/^I see a invalid forgot password email message$/) do
  page.should have_selector ".alert", text: "Email Invalid: The email you specified is invalid. Please check the spelling, formatting and that it is an active address."
end

When(/^I give an invalid pcvid$/) do
  delete_user ; create_user
  fill_in "email@email.com", :with => @user[:email] # GOOD
  fill_in "PCV ID", :with => "" # BAD
  click_button "Submit"
end

Then(/^I see a invalid forgot password pcvid message$/) do
  page.should have_selector ".alert", text: "PCVID Invalid: Your request was not submitted because the PCVID was incorrect. Please resubmit your request in this format: PCVID, Supply short name, dose, qty, location."
end

When(/^I give all valid inputs$/) do
  delete_user ; create_user
  fill_in "email@email.com", :with => @user[:email] # GOOD
  fill_in "PCV ID", :with => @user[:pcv_id] # GOOD
  click_button "Submit"
end

Then(/^I see a successful message$/) do
  page.should have_selector ".alert", text: "Success! A temporary password has been sent to the email we have on file. Please check your e-mail and click on the link to complete the log in. (web experience)"
end
#save_and_open_page
