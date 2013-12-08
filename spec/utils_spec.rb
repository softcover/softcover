require 'spec_helper'

describe Softcover::Utils do
  context "book_txt_lines" do
    before do
      Softcover::Utils.stub(:raw_lines).and_return(['foo.md', '# bar.tex'])
    end
    subject { Softcover::Utils.book_txt_lines }
    it { should     include 'foo.md' }
    it { should_not include 'bar.tex' }
  end
end