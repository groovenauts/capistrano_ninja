require "capistrano_ninja/ext"

require 'capistrano/logger'

module CapistranoNinja
  module Ext
    module Logger

      def self.included(m)
        m.module_eval do
          alias_method :log_without_ninja, :log
          alias_method :log, :log_with_ninja
        end
      end

      LEVEL_NAMES = %w[IMPORTANT INFO DEBUG TRACE].each_with_object({}){|name, d|
        d[ ::Capistrano::Logger.const_get(name) ] = name.downcase
      }.freeze


      def logger
        CapistranoNinja.logger
      end

      def tag_base
        @tag_base ||= CapistranoNinja.config.tag_base
      end

      def servers
        @servers ||= []
      end

      def log_with_ninja(level, message, line_prefix=nil, &block)
        result = log_without_ninja(level, message, line_prefix, &block)
        begin
          local_msg = line_prefix ? "[#{line_prefix}] #{message}" : message
          map = {"level" => LEVEL_NAMES[level], "message" => local_msg}
          # map["line_prefix"] = line_prefix if line_prefix
          logger.post("#{tag_base}.local_logs", map)

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
              logger.post("#{tag_base}.remote_logs", {"level" => LEVEL_NAMES[level], "message" => @remote_command, "server" => line_prefix})
            end
          when /\A\[(.+)\]\s+(.+)\Z/ then
            server = $1
            body = $2.strip
            if @uploaded_filepath && body =~ /\A#{Regexp.escape(@uploaded_filepath)}\Z/
              logger.post("#{tag_base}.remote_logs",
                          { "level" => LEVEL_NAMES[level], "message" => @uploading_command,
                            "server" => server, "from" => CapistranoNinja.config.local_hostname})
              @uploaded_filepath = nil
            else
              logger.post("#{tag_base}.remote_logs",
                          { "level" => LEVEL_NAMES[level], "message" => body,
                            "server" => server})
            end
          end
        rescue => e
          log_without_ninja(::Capistrano::Logger::INFO, "[#{e.class}] #{e.message}")
        end
        return result
      end

    end
  end
end
