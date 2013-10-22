# Load the rails application
require File.expand_path('../application', __FILE__)

# Load the secrets file
require 'yaml'
SECRETS = OpenStruct.new(YAML::load(IO.read(File.join(Rails.root, 'config', 'secret', 'secrets.yml')))[Rails.env])

# Initialize the rails application
CoursePacker::Application.initialize!
