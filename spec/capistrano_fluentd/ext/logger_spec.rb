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
  let(:local_hostname){ "host01" }
  before{ CapistranoFluentd.stub(:logger).and_return(fld_logger) }
  before{ CapistranoFluentd.stub(:tag_base).and_return("cap") }
  before{ CapistranoFluentd.stub(:local_hostname).and_return(local_hostname) }

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
           ["cap.local.log" , {"level" => messages[3][0], "message" => "[#{server}] " + messages[3][1]}],
           # insert cap.remote.log message which is replaced  "executing command" into actual command
           ["cap.remote.log", {"level" => messages[3][0], "message" => messages[1][1], "server" => server}],
           ["cap.local.log" , {"level" => messages[4][0], "message" => messages[4][1]}],
        ]
        expect(fld_logger.logs).to eq expected
      end
    end


    context "3 servers" do
      let(:server1){ "192.168.55.101" }
      let(:server2){ "192.168.55.102" }
      let(:server3){ "192.168.55.103" }
      let(:messages){
        [
         [debug, "`deploy:setup_deploy_config_file'"],
         [debug, "executing \"mkdir -p '/srv/test_app/shared/config/deploy'\""],
         [trace, "servers: [\"#{server1}\", \"#{server2}\", \"#{server3}\"]"],
         [trace, "executing command", "#{server1}"],
         [trace, "executing command", "#{server2}"],
         [trace, "executing command", "#{server3}"],
         [trace, "command finished in 49ms"],
        ]
      }

      before do
        messages.each{|msg| cap_logger.log *msg }
      end

      it { expect(cap_logger.servers).to eq [server1, server2, server3] }
      it { expect(cap_logger.logs).to eq messages.map{|args| {level: args[0], message: args[1], line_prefix: args[2], } } }
      it do
        expected = [
           ["cap.local.log" , {"level" => messages[0][0], "message" => messages[0][1]}],
           ["cap.local.log" , {"level" => messages[1][0], "message" => messages[1][1]}],
           ["cap.local.log" , {"level" => messages[2][0], "message" => messages[2][1]}],
           ["cap.local.log" , {"level" => messages[3][0], "message" => "[#{server1}] " + messages[3][1]}],
           ["cap.remote.log", {"level" => messages[3][0], "message" => messages[1][1], "server" => server1}],
           ["cap.local.log" , {"level" => messages[4][0], "message" => "[#{server2}] " + messages[4][1]}],
           ["cap.remote.log", {"level" => messages[4][0], "message" => messages[1][1], "server" => server2}],
           ["cap.local.log" , {"level" => messages[5][0], "message" => "[#{server3}] " + messages[5][1]}],
           ["cap.remote.log", {"level" => messages[5][0], "message" => messages[1][1], "server" => server3}],
           ["cap.local.log" , {"level" => messages[6][0], "message" => messages[6][1]}],
        ]
        expect(fld_logger.logs).to eq expected
      end
    end

    #    servers: ["192.168.55.99"]
    # ** sftp upload /var/folders/70/5yxt0jys7ss_m71y5pz_l_qc0000gn/T/20140105030006.zip -> /tmp/20140105030006.zip
    #    [192.168.55.99] /tmp/20140105030006.zip
    #    [192.168.55.99] done
    #  * sftp upload complete
    context "sftp upload" do
      let(:server){ "192.168.55.101" }
      let(:messages){
        [
         [trace, "servers: [\"#{server}\"]"],
         [info , "sftp upload /var/folders/70/5yxt0jys7ss_m71y5pz_l_qc0000gn/T/20140105030006.zip -> /tmp/20140105030006.zip"],
         [trace, "[#{server}] /tmp/20140105030006.zip"],
         [trace, "[#{server}] done"],
         [debug, "sftp upload complete"],
        ]
      }

      before do
        messages.each{|msg| cap_logger.log *msg }
      end

      it { expect(cap_logger.servers).to eq [server] }
      it { expect(cap_logger.logs).to eq messages.map{|args| {level: args[0], message: args[1], line_prefix: args[2], } } }
      it do
        expected = [
           ["cap.local.log" , {"level" => messages[0][0], "message" => messages[0][1]}],
           ["cap.local.log" , {"level" => messages[1][0], "message" => messages[1][1]}],
           ["cap.local.log" , {"level" => messages[2][0], "message" => messages[2][1]}],
           ["cap.remote.log", {"level" => messages[2][0], "message" => messages[1][1], "server" => server, "from" => local_hostname }],
           ["cap.local.log" , {"level" => messages[3][0], "message" => messages[3][1]}],
           ["cap.remote.log", {"level" => messages[3][0], "message" => "done", "server" => server}],
           ["cap.local.log" , {"level" => messages[4][0], "message" => messages[4][1]}],
        ]
        expect(fld_logger.logs).to eq expected
      end
    end

  end


  context "executing command locally" do
    #   * 2014-01-05 11:57:45 executing `deploy:update_code'
    # branch or tag : [master]
    #     executing locally: "git ls-remote git@github.com:groovenauts/test_app.git master"
    #     command finished in 3739ms
    context "sftp upload" do
      let(:server){ "192.168.55.101" }
      let(:messages){
        [
         [debug, "executing `deploy:update_code'"],
         [trace, "executing locally: \"git ls-remote git@github.com:tengine/fontana.git master\""],
         [trace, "command finished in 3739ms"],
        ]
      }

      before do
        messages.each{|msg| cap_logger.log *msg }
      end

      it { expect(cap_logger.servers).to eq [] }
      it { expect(cap_logger.logs).to eq messages.map{|args| {level: args[0], message: args[1], line_prefix: args[2], } } }
      it do
        expected = [
           ["cap.local.log" , {"level" => messages[0][0], "message" => messages[0][1]}],
           ["cap.local.log" , {"level" => messages[1][0], "message" => messages[1][1]}],
           ["cap.local.log" , {"level" => messages[2][0], "message" => messages[2][1]}],
        ]
        expect(fld_logger.logs).to eq expected
      end
    end
  end

end
