run 'pgrep spring | xargs kill -9'

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'

#{"gem 'bootsnap', require: false" if Rails.version >= "5.2"}
gem 'devise'
gem 'figaro'
gem 'jbuilder', '~> 2.0'
gem 'pg', '~> 0.21'
gem 'puma'
gem 'rails', '#{Rails.version}'
gem 'redis'

gem 'autoprefixer-rails'
gem 'bootstrap', '~> 4.1', '>= 4.1.1'
gem 'bootstrap-sass', '~> 3.3'
gem 'font-awesome-sass', '~> 5.0.9'
gem 'sass-rails'
gem 'simple_form'
gem 'uglifier'
gem 'webpacker'
gem 'faker', :git => 'https://github.com/stympy/faker.git', :branch => 'master'

group :development do
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'database_cleaner'
  gem 'rspec-rails', '~> 3.7'
  gem 'capybara'
  gem 'cucumber-rails', require: false
  gem 'autotest-rails'
  gem 'selenium-webdriver'
  gem 'chromedriver-helper'
  gem 'launchy'
  gem 'factory_bot_rails'
  gem 'webmock', '~> 3.4', '>= 3.4.2'
end
RUBY

# Ruby version
########################################
file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML

# Spring conf file
########################################
inject_into_file 'config/spring.rb', before: ').each { |path| Spring.watch(path) }' do
  '  config/application.yml\n'
end

# Assets
########################################
run 'rm -rf app/assets/stylesheets'
run 'rm -rf vendor'
run 'curl -L https://github.com/lewagon/rails-stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm -f stylesheets.zip && rm -f app/assets/rails-stylesheets-master/README.md && mv app/assets/rails-stylesheets-master app/assets/stylesheets'
inject_into_file 'app/assets/stylesheets/config/_bootstrap_variables.scss', before: '// Override other variables below!' do
"
// Patch to make simple_form compatible with bootstrap 3
.invalid-feedback {
  display: none;
  width: 100%;
  margin-top: 0.25rem;
  font-size: 80%;
  color: $red;
}

.was-validated .form-control:invalid,
.form-control.is-invalid,
.was-validated .custom-select:invalid,
.custom-select.is-invalid {
  border-color: $red;
}

.was-validated .form-control:invalid ~ .invalid-feedback,
.was-validated .form-control:invalid ~ .invalid-tooltip,
.form-control.is-invalid ~ .invalid-feedback,
.form-control.is-invalid ~ .invalid-tooltip,
.was-validated .custom-select:invalid ~ .invalid-feedback,
.was-validated .custom-select:invalid ~ .invalid-tooltip,
.custom-select.is-invalid ~ .invalid-feedback,
.custom-select.is-invalid ~ .invalid-tooltip {
  display: block;
}

"
end

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require rails-ujs
//= require_tree .
JS

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">########################################
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
    <title>TODO</title>
    <%= csrf_meta_tags %>
    <%= action_cable_meta_tag %>
    <%= stylesheet_link_tag 'application', media: 'all' %>
    <%#= stylesheet_pack_tag 'application', media: 'all' %> <!-- Uncomment if you import CSS in app/javascript/packs/application.js -->
  </head>
  <body>
    <%= render 'shared/navbar' %>
    <%= render 'shared/flashes' %>
    <%= yield %>
    <%= javascript_include_tag 'application' %>
    <%= javascript_pack_tag 'application' %>
  </body>
</html>
HTML

file 'app/views/shared/_flashes.html.erb', <<-HTML
<% if notice %>
  <div class="alert alert-info alert-dismissible" role="alert">
    <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    <%= notice %>
  </div>
<% end %>
<% if alert %>
  <div class="alert alert-warning alert-dismissible" role="alert">
    <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
    <%= alert %>
  </div>
<% end %>
HTML

run 'curl -L https://raw.githubusercontent.com/lewagon/awesome-navbars/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb'
run 'curl -L https://raw.githubusercontent.com/RamassamyM/rails-templates-june-2018/master/logo.png > app/assets/images/logo.png'

# README
########################################
markdown_file_content = <<-MARKDOWN
Rails app made by Michael Ramassamy
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generators
########################################
generators = <<-RUBY
config.generators do |generate|
      generate.assets false
      generate.helper false
      generate.test_framework :rspec
    end
RUBY

environment generators

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')
  generate('rspec:install')
  generate('cucumber:install')

  # Routes
  ########################################
  route "root to: 'pages#home'"

  # Git ignore
  ########################################
  run 'rm .gitignore'
  file '.gitignore', <<-TXT
.bundle
log/*.log
tmp/**/*
tmp/*
!log/.keep
!tmp/.keep
*.swp
.DS_Store
public/assets
public/packs
public/packs-test
node_modules
yarn-error.log
.byebug_history
TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
end
RUBY

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<-RUBY
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
  end
end
RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'rm app/javascript/packs/application.js'
  run 'yarn add jquery bootstrap@4.1.1'
  file 'app/javascript/packs/application.js', <<-JS
import "bootstrap";
JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do
<<-JS
// Bootstrap 3 (à vérifier avec 4.1.1) has a dependency over jQuery:
const webpack = require('webpack')
environment.plugins.prepend('Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery'
  })
)

JS
  end

  # Figaro
  ########################################
  run 'bundle binstubs figaro'
  run 'figaro install'

  # LDAP
  ########################################
  file 'config/initializers/ldap_authenticatable.rb', <<-RUBY
require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        if params[:user]
          ldap = Net::LDAP.new
          ldap.host = [YOUR LDAP HOSTNAME]
          ldap.port = [YOUR LDAP HOSTNAME PORT]
          ldap.auth email, password
        
          if ldap.bind
            user = User.find_or_create_by(email: email)
            success!(user)
          else
            return fail(:invalid_login)
          end
        end
      end
      
      def email
        params[:user][:email]
      end

      def password
        params[:user][:password]
      end

    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
RUBY

inject_into_file 'config/initializers/devise.rb', after: 'Devise.setup do |config|' do
<<-RUBY
  config.warden do |manager|
    manager.default_strategies(:scope => :user).unshift :ldap_authenticatable
  end
RUBY
  end  
  
  # Rubocop
  ########################################
  file '.rubocop.yml', <<-YML
AllCops:
  Exclude:
    - 'bin/**/*'
    - 'db/**/*'
    - 'config/**/*'
    - 'node_modules/**/*'
    - 'script/**/*'
    - 'support/**/*'
    - 'tmp/**/*'
    - 'test/**/*'

ConditionalAssignment:
  Enabled: false
StringLiterals:
  Enabled: false
RedundantReturn:
  Enabled: false
Documentation:
  Enabled: false
WordArray:
  Enabled: false
AbcSize:
  Enabled: false
MutableConstant:
  Enabled: false
SignalException:
  Enabled: false
Casecmp:
  Enabled: false
CyclomaticComplexity:
  Enabled: false
MethodMissing:
  Enabled: false
Style/FrozenStringLiteralComment:
  Enabled: false
LineLength:
  Max: 120
Style/EmptyMethod:
  Enabled: false
Bundler/OrderedGems:
  Enabled: false
YML

  # Git
  ########################################
  git :init
  git add: '.'
  git commit: "-m 'Initial commit with devise template"
end
