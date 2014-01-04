require "capistrano_fluentd"

module CapistranoFluentd
  class StaticTagLogger < Fluent::Logger
    def initialize(tag, options = {})
      @tag = tag
      super(options)
    end

    def post(map)
      super(@tag, map)
    end
  end

end
