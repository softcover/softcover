require 'spec_helper'

describe Polytexnic::Builders::Html do
  context "in valid MD directory" do
    before { chdir_to_md_book }

    context "#build!" do
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