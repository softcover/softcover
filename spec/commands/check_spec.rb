require 'spec_helper'
require 'stringio'

module Kernel

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out.string
  ensure
    $stdout = STDOUT
  end

end

describe Softcover::Commands::Check do

  subject(:check) do
    capture_stdout do
      Softcover::Commands::Check.check_dependencies!
    end
  end

  it { should match /all dependencies satisfied/i }

  describe "missing dependencies" do
    before do
      Softcover::Commands::Check.stub(:present?).with(:latex).and_return(false)
      Softcover::Commands::Check.stub(:present?).with(:calibre).
                                                 and_return(false)
    end

    it { should match /Checking for LaTeX.*Not found/ }
    it { should match /Checking for Calibre.*Not found/ }
  end
end
