require 'rake'
require 'rake/gempackagetask'
require 'rake/testtask'

task :default => :test

desc "Run all tests"
task :test => [ 'test/gen_ref', :deptests ]

# Requires test/test.ref to have been generated. Run 'tests' instead.
Rake::TestTask.new { |t|
    t.name = :deptests
    t.libs << 'lib'
    t.test_files = FileList['test/test_*.rb', 'test/ref.rb']
    t.verbose = true
}

# Compile and run the reference data generator
file "test/test.ref" => "test/gen_ref" do |t|
    sh %{#{t.prerequisites[0]}}
end

file "test/gen_ref" => "test/gen_ref.c" do |t|
    sh %{cc -Wall -Werror -o #{t.name} #{t.prerequisites[0]}}
end

load 'ruby-xdr.gemspec'
Rake::GemPackageTask.new(GEMSPEC) {}
