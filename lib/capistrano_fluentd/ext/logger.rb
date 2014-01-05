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

      # from Capistrano::Logger
      # IMPORTANT = 0
      INFO      = 1
      # DEBUG     = 2
      # TRACE     = 3

      def logger
        CapistranoFluentd.logger
      end

      def tag_base
        CapistranoFluentd.tag_base
      end

      def servers
        @servers ||= []
      end

      def log_with_fluentd(level, message, line_prefix=nil, &block)
        result = log_without_fluentd(level, message, line_prefix, &block)
        begin
          case message
          when /\Aservers: \[(.+)\]\Z/ then
            @servers = $1.split(/,/).map{|s| s.gsub(/\A\"|\"\Z/, '')}
          when /\Aexecuting \".+\"\Z/ then
            @remote_command = message
          when "executing command" then
            if line_prefix && servers.include?(line_prefix)
              logger.post("#{tag_base}.remote.log", {"level" => level, "message" => @remote_command, "server" => line_prefix})
            end
          end
          map = {"level" => level, "message" => message}
          # map["line_prefix"] = line_prefix if line_prefix
          logger.post("#{tag_base}.local.log", map)
        rescue => e
          log_without_fluentd(INFO, "[#{e.class}] #{e.message}")
        end
        return result
      end

    end
  end
end
