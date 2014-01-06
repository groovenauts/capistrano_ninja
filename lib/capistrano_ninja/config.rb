require "capistrano_ninja"

require 'socket'

module CapistranoNinja
  class Config
    attr_accessor :tag_base, :id_generator
    attr_accessor :host, :port, :ninja_options
    attr_writer :local_hostname

    def initialize
      @tag_base = "cap"
      @host = "localhost"
      @port = 24224
      @id_generator = Proc.new{ SecureRandom.uuid }
    end

    def local_hostname
      @local_hostname ||= Socket::gethostname
    end
    
  end
end
