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
          local_msg = line_prefix ? "[#{line_prefix}] #{message}" : message
          map = {"level" => level, "message" => local_msg}
          # map["line_prefix"] = line_prefix if line_prefix
          logger.post("#{tag_base}.local.log", map)

          case message
          when /\Aservers: \[(.+)\]\Z/ then
            @servers = $1.split(/\s*,\s*/).map{|s| s.gsub(/\A\"|\"\Z/, '')}
          when /\Aexecuting \".+\"\Z/ then
            @remote_command = message
          when /\Asftp upload .+ -> (.+)\Z/ then
            @uploading_command = message
            @uploaded_filepath = $1
          when "executing command" then
            if line_prefix && servers.include?(line_prefix)
              logger.post("#{tag_base}.remote.log", {"level" => level, "message" => @remote_command, "server" => line_prefix})
            end
          when /\A\[(.+)\]\s+(.+)\Z/ then
            server = $1
            body = $2
            if @uploaded_filepath && body =~ /\A#{Regexp.escape(@uploaded_filepath)}\Z/
              logger.post("#{tag_base}.remote.log",
                          { "level" => level, "message" => @uploading_command,
                            "server" => server, "from" => CapistranoFluentd.local_hostname})
              @uploaded_filepath = nil
            else
              logger.post("#{tag_base}.remote.log",
                          { "level" => level, "message" => body,
                            "server" => server})
            end
          end
        rescue => e
          log_without_fluentd(INFO, "[#{e.class}] #{e.message}")
        end
        return result
      end

    end
  end
end
