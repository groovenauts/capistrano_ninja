require "capistrano_fluentd"

module CapistranoFluentd
  class Config
    attr_accessor :tag, :id_generator

    attr_accessor :host, :port, :fluentd_options

    def initialize
      @tag = "cap"
      @host = "localhost"
      @port = 24224
      @id_generator = Proc.new{ SecureRandom.uuid }
      
    end
    
  end
end
