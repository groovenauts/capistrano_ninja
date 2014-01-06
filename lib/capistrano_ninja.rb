require "capistrano_ninja/version"

require 'securerandom'

module CapistranoNinja
  autoload :Ext            , "capistrano_ninja/ext"
  autoload :Config         , "capistrano_ninja/config"
  autoload :StaticTagLogger, "capistrano_ninja/static_tag_logger"

  class << self
    attr_accessor :tag, :command_id

    def config
      @config ||= Config.new
    end

    def logger
      unless @logger
        @logger = StaticTagLogger.new(config.tag, config.ninja_options || {})
        @logger.extra.update(:id => config.id_generator.call)
      end
      @logger
    end

    def configure
      yield(config) if block_given?
      Capistrano::Logger.module_eval do
        include CapistranoNinja::Ext::Logger
      end
      logger.post("#{config.tag_base}.log", {program: "capistrano", command: "#{$PROGRAM_NAME} #{ARGV.join(' ')}", from: config.local_hostname})
    end

  end
end
