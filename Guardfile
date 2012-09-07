####### When to reload environment #######
# Brackets specify specific environment (i.e. rspec)
guard 'spork', :cucumber_env => { 'RAILS_ENV' => 'test' }, :rspec_env => { 'RAILS_ENV' => 'test' } do
  watch('config/application.rb')
  watch('config/environment.rb')
  watch(%r{^config/environments/.+\.rb$})
  watch(%r{^config/initializers/.+\.rb$})
  watch('Gemfile')
  watch('Gemfile.lock')

  watch('spec/spec_helper.rb')       { :rspec }
  watch(%r{^spec/factories/(.+)\.rb$}) { :rspec }
  watch(%r{^spec/support/(.+)\.rb$}) { :rspec }

  watch('test/test_helper.rb')       { :test_unit }
  watch(%r{features/support/})       { :cucumber }
end


####### When to run a Spec #######

# For when Full Ruby Backtraces are needed
# guard 'rspec', :version => 2, :cli => '--drb --format documentation -b', :all_on_start => false, :all_after_pass => false do

guard 'rspec', :version => 2, :cli => '--drb --format documentation', :all_on_start => false, :all_after_pass => false do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }

  # Commented since Routing specs don't exist
  # watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }

  # Models and Controllers
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb"] }

  # Commented since running all specs is annoying
  # watch(%r{^spec/factories/(.+)\.rb$})                { "spec" }
  # watch(%r{^lib/(.+)\.rb$})                           { "spec" }

  # Commented since Routing specs don't exist
  # watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }

  # Capybara request specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/requests/#{m[1]}_spec.rb" }
end
