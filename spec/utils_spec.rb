require 'spec_helper'

describe Softcover::Utils do
  context "book_file_lines" do
    let(:raw_lines) { ['foo.md', '# bar.tex'] }
    subject { Softcover::Utils.non_comment_lines(raw_lines) }
    it { should     include 'foo.md' }
    it { should_not include 'bar.tex' }
  end
end