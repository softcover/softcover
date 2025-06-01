require 'spec_helper'

module OutputTest
  include Softcover::Output
  extend self

  def puts_hello
    puts 'hello'
  end

  def print_hello
    print 'hello'
  end

  def printf_hello
    print 'hello'
  end

  def system_cmd
    system "echo hello"
  end
end

describe Softcover::Output do
  before { Softcover::Output.unsilence! }

  it 'redirects output' do
    Softcover::Output.stream = $stderr
    expect($stderr).to receive(:puts).with('hello')
    expect($stderr).to receive(:print).twice.with('hello')
    

    OutputTest.puts_hello
    OutputTest.print_hello
    OutputTest.printf_hello
  end

  it 'redirects system command output' do
    expect(Softcover::Output.stream).to receive(:puts)
    OutputTest.system_cmd
  end
end
