# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

ActiveRecord::SchemaDumper.ignore_tables = ['deprecated_preview_cards']
# Rails.logger.level = Logger::WARN
