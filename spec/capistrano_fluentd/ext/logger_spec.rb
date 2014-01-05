require 'spec_helper'

describe CapistranoFluentd::Ext::Logger do

  important = 0
  info      = 1
  debug     = 2
  trace     = 3

  class MockFluentdLogger
    attr_reader :logs

    def initialize
      @logs = []
    end

    def post(tag, map)
      @logs << [tag, map]
    end
  end

  class MockCapLogger
    attr_reader :logs

    def initialize
      @logs = []
    end

    def log(level, message, line_prefix=nil)
      @logs << {level: level, message: message, line_prefix: line_prefix}
    end

    include CapistranoFluentd::Ext::Logger
  end

  let(:fld_logger){ MockFluentdLogger.new }
  let(:cap_logger){ MockCapLogger.new }
  before{ CapistranoFluentd.stub(:logger).and_return(fld_logger) }
  before{ CapistranoFluentd.stub(:tag_base).and_return("cap") }

  context "servers" do
    it { expect(cap_logger.servers).to be_empty }

    context "server 192.168.55.99" do
      let(:server){ "192.168.55.99" }
      let(:msg){ "servers: [\"#{server}\"]" }
      before{ cap_logger.log(trace, msg, nil) }
      it { expect(cap_logger.servers).to eq [server] }
      it { expect(cap_logger.logs).to eq [{level: trace, message: msg, line_prefix: nil}] }
      it { expect(fld_logger.logs).to eq [["cap.local.log", {"level" => trace, "message" => msg}]] }
    end
  end


  # * 2014-01-05 11:57:45 executing `deploy:setup_deploy_config_file'
  # * executing "mkdir -p '/srv/test_app/shared/config/deploy'"
  #   servers: ["192.168.55.99"]
  #   [192.168.55.99] executing command
  #   command finished in 51ms

  context "executing command remotely" do
    context "sigle server" do
      let(:server){ "192.168.55.99" }
      let(:messages){
        [
         [debug, "`deploy:setup_deploy_config_file'"],
         [debug, "executing \"mkdir -p '/srv/test_app/shared/config/deploy'\""],
         [trace, "servers: [\"#{server}\"]"],
         [trace, "executing command", "#{server}"],
         [trace, "command finished in 49ms"],
        ]
      }

      before do
        messages.each do |msg|
          cap_logger.log *msg
        end
      end

      it { expect(cap_logger.servers).to eq [server] }
      it { expect(cap_logger.logs).to eq messages.map{|args| {level: args[0], message: args[1], line_prefix: args[2], } } }
      it do
        expected = [
           ["cap.local.log" , {"level" => messages[0][0], "message" => messages[0][1]}],
           ["cap.local.log" , {"level" => messages[1][0], "message" => messages[1][1]}],
           ["cap.local.log" , {"level" => messages[2][0], "message" => messages[2][1]}],
           # insert cap.remote.log message which is replaced  "executing command" into actual command
           ["cap.remote.log", {"level" => messages[3][0], "message" => messages[1][1], "server" => server}],
           ["cap.local.log" , {"level" => messages[3][0], "message" => messages[3][1]}],
           ["cap.local.log" , {"level" => messages[4][0], "message" => messages[4][1]}],
        ]
        expect(fld_logger.logs).to eq expected
      end
    end
  end



  #   servers: ["192.168.55.99"]
  # ** sftp upload /var/folders/70/5yxt0jys7ss_m71y5pz_l_qc0000gn/T/20140105030006.zip -> /tmp/20140105030006.zip
  #    [192.168.55.99] /tmp/20140105030006.zip
  #    [192.168.55.99] done
  #  * sftp upload complete
  #  * executing "cd /srv/test_app/releases && unzip -q /tmp/20140105030006.zip && rm /tmp/20140105030006.zip"
  #    servers: ["192.168.55.99"]
  #    [192.168.55.99] executing command
  #    command finished in 141ms



  #   * 2014-01-05 11:57:45 executing `deploy:update_code'
  # branch or tag : [master]
  #     executing locally: "git ls-remote git@github.com:groovenauts/test_app.git master"
  #     command finished in 3739ms


end
