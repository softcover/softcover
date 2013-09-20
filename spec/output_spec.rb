require 'spec_helper'

module OutputTest
  include Polytexnic::Output
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

describe Polytexnic::Output do
  before { Polytexnic::Output.unsilence! }

  it 'redirects output' do
    Polytexnic::Output.stream = $stderr
    $stderr.should_receive(:puts).with('hello')
    $stderr.should_receive(:print).twice.with('hello')

    OutputTest.puts_hello
    OutputTest.print_hello
    OutputTest.printf_hello
  end

  it 'redirects system command output' do
    Polytexnic::Output.stream.should_receive(:puts)
    OutputTest.system_cmd
  end
end
