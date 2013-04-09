require 'spec_helper'

describe Polytexnic::Builders::Html do

  context "in valid tex directory" do
    before { chdir_to_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }
      before { builder.build! }

      its(:built_files) { should include "html/book.html" }

      describe "HTML output" do
        let(:output) { File.open("html/book.html").read }
        subject { output }

        it { should match('<!DOCTYPE html>') }
        it { should match('pygments.css') }

        it "should generate a Pygments stylesheet" do
          expect('html/stylesheets/pygments.css').to exist
        end
      end

      after(:all) do
        chdir_to_book
        builder.clean!
      end
    end
  end

  context "in valid MD directory" do
    before { chdir_to_md_book }

    describe "#build!" do
      subject(:builder) { Polytexnic::Builders::Html.new }

      before { builder.build! }

      2.times do |i|
        its(:built_files) { should include "html/chapter#{i+1}.html" }
        its(:built_files) { should include "html/chapter#{i+1}_fragment.html" }
      end

      after(:all) do
        chdir_to_md_book
        builder.clean!
      end
    end
  end
end