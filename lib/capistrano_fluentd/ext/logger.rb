require "capistrano_fluentd/ext"

require 'fluent-logger'

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
          tag = c.delete(:tag) || "capistrano"
          @fluent = StaticTagLogger.new(tag, c)
        end
        @fluent
      end

      def log_with_fluentd(level, message, line_prefix=nil, &block)
        result = log_without_fluentd(level, message, line_prefix, &block)
        begin
          msg = line_prefix ? "[#{line_prefix}] #{message}" : "#{message}"
puts "_____________________" + msg
          fluent.post({"level" => level, "message" => msg})
        rescue => e
          log_without_fluentd(INFO, "[#{e.class}] #{e.message}")
        end
        return result
      end

    end
  end
end
