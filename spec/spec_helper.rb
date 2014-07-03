require 'table_differ'
require 'database_cleaner'


RSpec.configure do |config|
  config.order = :random

  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    expectations.syntax = :expect
  end

  config.before(:suite) do
    if false
      ActiveRecord::Base.logger = Logger.new(STDERR)
      ActiveRecord::Base.logger.level = Logger::ERROR
      ActiveRecord::Base.logger.level = Logger::DEBUG
    end

    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database  => ":memory:")

    ActiveRecord::Schema.define do
      create_table :models do |table|
        table.column :name, :string
      end

      create_table :surrogate_models do |table|
        table.column :name, :string
        table.column :original_name, :string
        table.column :alternate_value, :string
      end
    end

    # need to explicitly specify active_record since we don't have a database.yml?
    DatabaseCleaner[:active_record].strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end


RSpec.shared_context "model" do
  class Model < ActiveRecord::Base
    include TableDiffer
  end
end

RSpec.shared_context "surrogate_model" do
  class SurrogateModel < ActiveRecord::Base
    include TableDiffer
  end
end

=begin
  maybe later...

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10
=end
