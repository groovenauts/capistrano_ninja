require "capistrano_fluentd"

module CapistranoFluentd
  module Ext
    autoload :Logger, "capistrano_fluentd/ext/logger"
  end
end
