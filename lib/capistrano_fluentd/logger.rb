require "capistrano_fluentd"

module CapistranoFluentd
  class Logger
    def initialize(orig, options = {})
      @orig = orig
      @fluent_tag = options.delete("tag") || options.delete(:tag) || "capistrano"
      @fluent = Fluent::Logger.new(options)
    end

    IMPORTANT = 0
    INFO      = 1
    DEBUG     = 2
    TRACE     = 3

    def log(level, message, line_prefix=nil, &block)
      result = @orig.log(level, message, line_prefix, &block)
      begin
        msg = line_prefix ? "[#{line_prefix}] #{message}" : "#{message}"
        @fluent.post(@fluent_tag, {"level" => level, "message" => msg})
      rescue => e
        @orig.log(INFO, "[#{e.class}] #{e.message}")
      end
      return result
    end
  end
end
