require "capistrano_fluentd/ext"

module CapistranoFluentd
  module Ext
    module Logger
      def self.included(m)
        m.module_eval do
          alias_method :log_without_fluentd, :log
          alias_method :log, :log_with_fluentd
        end
      end

      def fluent
        unless @fluent
          c = CapistranoFluentd.config.dup
          tag = c.delete(:tag)
          @fluent = StaticTagLogger.new(tag, c)
        end
        @fluent
      end

      # from Capistrano::Logger
      # IMPORTANT = 0
      INFO      = 1
      # DEBUG     = 2
      # TRACE     = 3

      def log_with_fluentd(level, message, line_prefix=nil, &block)
        result = log_without_fluentd(level, message, line_prefix, &block)
        begin
          map = {"level" => level, "message" => message}
          map["line_prefix"] = line_prefix if line_prefix
          fluent.post_without_tag(map)
        rescue => e
          log_without_fluentd(INFO, "[#{e.class}] #{e.message}")
        end
        return result
      end

    end
  end
end
