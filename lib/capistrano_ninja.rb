require "capistrano_fluentd/version"

require 'securerandom'

module CapistranoFluentd
  autoload :Ext            , "capistrano_fluentd/ext"
  autoload :Config         , "capistrano_fluentd/config"
  autoload :StaticTagLogger, "capistrano_fluentd/static_tag_logger"

  class << self
    attr_accessor :tag, :command_id

    def config
      @config ||= Config.new
    end

    def logger
      unless @logger
        @logger = StaticTagLogger.new(config.tag, config.fluentd_options || {})
        @logger.extra.update(:id => config.id_generator.call)
      end
      @logger
    end

    def configure
      yield(config) if block_given?
      Capistrano::Logger.module_eval do
        include CapistranoFluentd::Ext::Logger
      end
      logger.post_without_tag({program: "capistrano", command: "#{$PROGRAM_NAME} #{ARGV.join(' ')}"})
    end

  end
end
