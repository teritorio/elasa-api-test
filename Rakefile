require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*.rb"]
end

task :default => :test



# require "bundler/gem_tasks"
# require "rake/testtask"

# Rake::TestTask.new do |t|
#   t.test_files = FileList['tests/**/*_test.rb']
# end
# desc "Run tests"

# task default: :test
