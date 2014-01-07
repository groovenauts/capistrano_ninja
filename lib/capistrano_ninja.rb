require "capistrano_ninja/version"

require 'securerandom'

module CapistranoNinja
  autoload :Ext         , "capistrano_ninja/ext"
  autoload :Config      , "capistrano_ninja/config"
  autoload :FluentLogger, "capistrano_ninja/fluent_logger"

  class << self
    attr_accessor :tag, :command_id

    def config
      @config ||= Config.new
    end

    def logger
      unless @logger
        @logger = FluentLogger.new(config.fluent_logger_options)
        @logger.extra.update(:id => config.id_generator.call, :command => "capistrano")
      end
      @logger
    end

    def configure
      yield(config) if block_given?
      Capistrano::Logger.module_eval do
        include CapistranoNinja::Ext::Logger
      end
      logger.post("#{config.tag_base}.executions", {program: "capistrano", command: "#{$PROGRAM_NAME} #{ARGV.join(' ')}", from: config.local_hostname})
    end

  end
end
