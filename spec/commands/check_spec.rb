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
      Softcover::Commands::Check.dependency_labels.each do |label|
        allow(Softcover::Commands::Check).to receive(:present?).with(label).and_return(false)
      end
    end

    it { should match /Checking for LaTeX.*Missing/ }
    it { should match /Checking for PhantomJS.*Missing/ }
    it { should match /Checking for Inkscape.*Missing/ }
    it { should match /Checking for Calibre.*Missing/ }
    it { should match /Checking for Java.*Missing/ }
    it { should match /Checking for EpubCheck.*Missing/ }
    it { should match /Checking for ImageMagick.*Missing/ }
    it { should match /Checking for Node\.js.*Missing/ }

    it { should match /Missing dependencies:/ }
    it { should match /LaTeX/ }
    it { should match /PhantomJS/ }
    it { should match /Inkscape/ }
    it { should match /Calibre/ }
    it { should match /Java/ }
    it { should match /EpubCheck/ }
    it { should match /ImageMagick/ }
    it { should match /Node\.js/ }
  end
end
