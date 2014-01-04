require "capistrano_fluentd/version"

module CapistranoFluentd
  autoload :Ext            , "capistrano_fluentd/ext"
  autoload :StaticTagLogger, "capistrano_fluentd/static_tag_logger"

  class << self
    def config
      @config ||= {
        :tag  => "capistrano",
        :host => "localhost",
        :port => 24224,
      }
    end

    def logger
      unless @logger
        c = config.dup
        tag = c.delete(:tag)
        @logger = StaticTagLogger.new(tag, c)
      end
      @logger
    end

  end
end
