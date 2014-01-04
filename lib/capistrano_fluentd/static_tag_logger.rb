require "capistrano_fluentd"

require 'fluent/logger'

module CapistranoFluentd
  class StaticTagLogger < Fluent::Logger::FluentLogger
    attr_reader :extra

    def initialize(tag, options = {})
      @tag = tag
      @extra = {}
      super(nil, options)
    end

    def post_without_tag(map)
      m = extra.dup.update(map)
      post(@tag, m)
    end
  end

end
