# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rspec/tabular'
require 'fakefs/spec_helpers'
require 'rspec/side_effects'
require 'etc'
# HACK: including pp seems to resolve an error with FakeFS and File.read
# This seems to be related to but not the same as the problem mentioned in the
# README
# https://github.com/fakefs/fakefs#fakefs-vs-pp-----typeerror-superclass-mismatch-for-class-file
require 'pp'

# Setup code coverage
require 'simplecov'
SimpleCov.start

require 'sugar_utils'
MultiJson.use(:ok_json)

SolidAssert.enable_assertions

RSpec.configure do |config|
  config.include FakeFS::SpecHelpers, fakefs: true
end

RSpec::Matchers.define :have_json_content do |expected|
  match do |actual|
    next false unless File.exist?(actual)

    @actual = MultiJson.load(File.read(actual))
    values_match?(expected, @actual)
  end

  diffable
end

RSpec::Matchers.define :have_content do |expected|
  match do |actual|
    next false unless File.exist?(actual)

    @actual = File.open(actual, 'r') { |f| f.read.chomp }
    values_match?(expected, @actual)
  end

  diffable
end

RSpec::Matchers.define :have_file_permission do |expected|
  match do |actual|
    next false unless File.exist?(actual)

    @actual   = format('%<mode>o', mode: File.stat(actual).mode)
    @expected = format('%<mode>o', mode: expected)
    values_match?(@expected, @actual)
  end
end

RSpec::Matchers.define :have_owner do |expected|
  match do |actual|
    next false unless File.exist?(actual)

    @actual   = Etc.getpwuid(File.stat(filename).uid).name
    @expected = expected
    values_match?(@expected, @actual)
  end
end

RSpec::Matchers.define :have_group do |expected|
  match do |actual|
    next false unless File.exist?(actual)

    @actual   = Etc.getgrgid(File.stat(actual).gid).name
    @expected = expected
    values_match?(@expected, @actual)
  end
end

RSpec::Matchers.define :have_mtime do |expected|
  match do |actual|
    next false unless File.exist?(actual)

    @actual   = File.stat(actual).mtime.to_i
    @expected = expected
    values_match?(@expected, @actual)
  end
end

RSpec::Matchers.define :be_directory do
  match do |actual|
    @actual   = File.directory?(actual)
    @expected = true
    values_match?(@expected, @actual)
  end
end
