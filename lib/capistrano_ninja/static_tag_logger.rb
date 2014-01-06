require "capistrano_ninja"

require 'fluent/logger'

module CapistranoNinja
  class StaticTagLogger < Fluent::Logger::FluentLogger
    attr_reader :extra

    def initialize(tag, options = {})
      @tag = tag
      @extra = {}
      super(nil, options)
    end

    def post(tag, map)
      m = extra.dup.update(map)
      post(tag, m)
    end

    def post_without_tag(map)
      m = extra.dup.update(map)
      post(@tag, m)
    end
  end

end
