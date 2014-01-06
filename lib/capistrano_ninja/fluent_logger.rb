require "capistrano_ninja"

require 'fluent/logger'

module CapistranoNinja
  class FluentLogger < ::Fluent::Logger::FluentLogger
    attr_reader :extra

    def initialize(options = {})
      @extra = {}
      super(nil, options)
    end

    def post(tag, map)
      m = extra.dup.update(map)
      super(tag, m)
    end

  end

end
