require "capistrano_fluentd"

require 'fluent/logger'

module CapistranoFluentd
  class StaticTagLogger < Fluent::Logger::FluentLogger
    def initialize(tag, options = {})
      @tag = tag
      super(nil, options)
    end

    def post_without_tag(map)
      post(@tag, map)
    end
  end

end
