require "mongoid"
require "granalytics/version"

module Granalytics
  # TODO: Add configuration to make Granalytics::Event persistence optional.

  def self.configure(&block)
    yield configuration
  end

  def self.configuration
    @configuration ||= Granalytics::Configuration.new
  end
end

require_dependency 'granalytics/configuration'
require_dependency 'granalytics/event'
require_dependency 'granalytics/aggregate'
require_dependency 'granalytics/data'
require_dependency 'granalytics/export'

if ::Rails
  require "granalytics/rails.rb"
end
