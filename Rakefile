require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'
require 'bundler'

namespace :gem do
  Bundler::GemHelper.install_tasks
end

namespace :test do
  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.rspec_opts = "--color"
  end

  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
  end
end

desc "Run all tests"
task :test => ['test:rspec', 'test:features']
