require 'spec_helper'

describe Softcover::Config do
  before do
    chdir_to_book
  end

  describe "path" do
    context "local path override" do
      before do
        `touch .softcover`
      end

      it "uses local path" do
        expect(Softcover::Config.path).to eq ".softcover"
      end

      after do
        `rm .softcover`
      end
    end

    context "system path" do
      it "uses home dir" do
        expect(Softcover::Config.path).to eq "~/.softcover"
      end
    end
  end

end
