require 'resthome'
require 'json'

class SendGridWebService < RESTHome
  base_uri 'https://sendgrid.com'

  namespace '/api' do
    # Profile
    route :profile, '/profile.get.json', :method => :post, :no_body => true
    route :set_profile, '/profile.set.json', :method => :post
    route :set_password, '/password.set.json', :method => :post
    route :set_username, '/profile.setUsername.json', :method => :post
    route :set_contact_email, '/profile.setEmail.json', :method => :post

    # Bounces
    route :bounces, '/bounces.get.json', :method => :post, :no_body => true
    # delete_bounce 'email' => 'email@to.delete'
    route :delete_bounce, '/bounces.delete.json', :method => :post

    # Unsubscribes
    route :unsubscribes, '/unsubscribes.get.json', :method => :post, :no_body => true
    # delete_unsubscribes 'email' => 'email@to.delete'
    route :delete_unsubscribes, '/unsubscribes.delete.json', :method => :post
    # add_unsubscribes 'email' => 'email@to.add'
    route :add_unsubscribes, '/unsubscribes.add.json', :method => :post

    # Spam Reports
    route :spam_reports, '/spamreports.get.json', :method => :post, :no_body => true
    # delete_spam_reports 'email' => 'email@to.delete'
    route :delete_spam_reports, '/spamreports.delete.json', :method => :post

    # Invalid Emails
    route :invalid_emails, '/invalidemails.get.json', :method => :post, :no_body => true
    # delete_invalid_emails 'email' => 'email@to.delete'
    route :delete_invalid_emails, '/invalidemails.delete.json', :method => :post

    # Statistics
    route :stats, '/stats.get.json', :method => :post

    # Event Notification Url
    route :notification_url, '/eventposturl.get.json', :method => :post, :no_body => true
    # set_notification_url 'url' => 'http://www.YourPostUrlHere.com'
    route :set_notification_url, '/eventposturl.set.json', :method => :post
    route :delete_notification_url, '/eventposturl.delete.json', :method => :post, :no_body => true

    # Reseller: Users
    route :users, '/user.profile.json', :method => :post
    route :disable_user, '/user.disable.json', :method => :post
    route :enable_user, '/user.enable.json', :method => :post
    route :add_user, '/user.add.json', :method => :post
    route :set_user_password, '/user.password.json', :method => :post

    # Reseller: User Statistics
    route :user_stats, '/user.stats.json', :method => :post

    # Reseller: User Bounces
    route :user_bounces, '/user.bounces.json', :method => :post
  end

  def initialize(username, password)
    @username = username
    @password = password
  end

  def parse_response!; end

  def get_profile
    data = self.profile
    data = data[0] if data.is_a?(Array)
    data
  end

  def edit_profile(body)
    self.set_profile body
  end

  def reset_password(new_password)
    data = self.set_password 'password' => new_password, 'confirm_password' => new_password
    if data.is_a?(Hash) && data['message'] == 'success'
      @password = new_password
    end
    data
  end

  def update_username(new_username)
    data = self.set_username 'username' => new_username
    if data.is_a?(Hash) && data['message'] == 'success'
      @username = new_username
    end
    data
  end

  def update_contact_email(email)
    self.set_contact_email 'email' => email
  end

  def get_bounces(date=1)
    self.bounces :body => {'date' => date}
  end

  def get_unsubscribes(date=1)
    self.unsubscribes :body => {'date' => date}
  end

  def get_spam_reports(date=1)
    self.spam_reports :body => {'date' => date}
  end

  def get_invalid_emails(date=1)
    self.invalid_emails :body => {'date' => date}
  end

  def get_stats_by_days(days=2, category=nil)
    data = self.stats 'days' => days, 'category' => category
    data = data[0] if data.is_a?(Array) && category && category.is_a?(String)
    data
  end

  def get_stats_by_range(start_date, end_date, category=nil)
    start_date = start_date.to_s('%Y-%m-%d') if start_date.is_a?(Time)
    end_date = end_date.to_s('%Y-%m-%d') if end_date.is_a?(Time)
    data = self.stats 'start_date' => start_date, 'end_date' => end_date, 'category' => category
    data = data[0] if data.is_a?(Array) && category && category.is_a?(String)
    data
  end

  def get_all_time_totals(category=nil)
    data = self.stats 'aggregate' => 1, 'category' => category
    data = data[0] if data.is_a?(Array) && category && category.is_a?(String)
    data
  end

  def get_categories
    self.stats 'list' => 'true'
  end

  def get_notification_url
    data = self.notification_url
    data = data[0] if data.is_a?(Array)
    data
  end

  # Reseller methods
  def get_users
    self.users 'task' => 'get'
  end

  def get_user(username)
    data = self.users 'task' => 'get', 'username' => username
    data = data[0] if data.is_a?(Array)
    data
  end

  def edit_user(username, fields={})
    self.users fields.merge('task' => 'set', 'user' => username)
  end

  def reset_user_password(username, new_password)
    self.set_user_password 'user' => username, 'password' => new_password, 'confirm_password' => new_password
  end

  def change_user_username(username, new_username)
    self.users 'task' => 'setUsername', 'user' => username, 'username' => new_username
  end

  def change_user_email(username, email)
    self.users 'task' => 'setEmail', 'user' => username, 'email' => email
  end

  def build_options!(options)
    super
    options[:body] ||= {}
    options[:body]['api_user'] = @username
    options[:body]['api_key'] = @password
    options[:body].delete('category') if options[:body].has_key?('category') && options[:body]['category'].nil?
  end
end
