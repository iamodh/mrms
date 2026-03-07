ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module AdminTestHelper
  def admin_login
    post admin_login_path, params: { id: ENV["ADMIN_ID"], password: ENV["ADMIN_PW"] }
  end
end

class ActionDispatch::IntegrationTest
  include AdminTestHelper
end
