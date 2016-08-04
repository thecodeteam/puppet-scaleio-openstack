source 'https://rubygems.org'

gem 'json_pure', '<2.0.2'

group :development, :test do
  gem 'puppetlabs_spec_helper',                 :require => false
  gem 'rspec-puppet',                           :require => false
  gem 'beaker-rspec',                           :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
