require "capistrano_fluentd/version"

require 'securerandom'

module CapistranoFluentd
  autoload :Ext            , "capistrano_fluentd/ext"
  autoload :StaticTagLogger, "capistrano_fluentd/static_tag_logger"

  class << self
    attr_accessor :tag, :command_id

    def config
      @config ||= {
        :tag  => "capistrano",
        :host => "localhost",
        :port => 24224,
        :uuid => SecureRandom.uuid,
      }
    end

    def logger
      unless @logger
        c = config.dup
        tag = c.delete(:tag)
        uuid = c.delete(:uuid)
        @logger = StaticTagLogger.new(tag, c)
        @logger.extra.update(:uuid => uuid)
      end
      @logger
    end

    def configure
      yield(self) if block_given?
      Capistrano::Logger.module_eval do
        include CapistranoFluentd::Ext::Logger
      end
      logger.post_without_tag({program: "capistrano", command: "#{$PROGRAM_NAME} #{ARGV.join(' ')}"})
    end

  end
end
