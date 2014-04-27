source 'https://rubygems.org'

gem "rails", "3.2.17"
gem "rake", "~> 10.1.1"
gem "jquery-rails", "~> 2.0.2"
gem "coderay", "~> 1.1.0"
gem "fastercsv", "~> 1.5.0", :platforms => [:mri_18, :mingw_18, :jruby]
gem "builder", "3.0.0"
gem "mime-types"
gem "awesome_nested_set", "2.1.6"

gem "capistrano"
gem 'rvm-capistrano'

gem "pg", ">= 0.11.0"

# Optional gem for LDAP authentication
group :ldap do
  gem "net-ldap", "~> 0.3.1"
end

# Optional gem for OpenID authentication
group :openid do
  gem "ruby-openid", "~> 2.3.0", :require => "openid"
  gem "rack-openid"
end

group :rmagick do
  # RMagick 2 supports ruby 1.9
  # RMagick 1 would be fine for ruby 1.8 but Bundler does not support
  # different requirements for the same gem on different platforms
  gem "rmagick", ">= 2.0.0"
end

group :markdown do
  # TODO: upgrade to redcarpet 3.x when ruby1.8 support is dropped
  gem "redcarpet", "~> 2.3.0"
end

group :production do
  gem 'unicorn'
end

group :development do
  gem "rdoc", ">= 2.4.2"
  gem "yard"
end

group :test do
  gem "shoulda", "~> 3.3.2"
  gem "mocha", ">= 0.14", :require => 'mocha/api'
  if RUBY_VERSION >= '1.9.3'
    gem "capybara", "~> 2.1.0"
    gem "selenium-webdriver"
  end
end

local_gemfile = File.join(File.dirname(__FILE__), "Gemfile.local")
if File.exists?(local_gemfile)
  puts "Loading Gemfile.local ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(local_gemfile)
end

# Load plugins' Gemfiles
Dir.glob File.expand_path("../plugins/*/Gemfile", __FILE__) do |file|
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  #TODO: switch to "eval_gemfile file" when bundler >= 1.2.0 will be required (rails 4)
  instance_eval File.read(file), file
end
