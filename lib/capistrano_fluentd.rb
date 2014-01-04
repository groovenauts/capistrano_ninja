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
  end
end
