# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!
Rails.logger.level = Logger::WARN

ActiveRecord::SchemaDumper.ignore_tables = ['deprecated_preview_cards']
