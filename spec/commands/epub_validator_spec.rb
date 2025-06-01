require 'spec_helper'

describe Softcover::Commands::EpubValidator do
  context 'epub file exists' do
    before(:all) do
      remove_book
      chdir_to_fixtures
      silence { `softcover new book --polytex` }
      chdir_to_book
      silence { `softcover build:epub` }
    end

    after(:all) { remove_book }

    subject { silence { Softcover::Commands::EpubValidator.validate! }  }
    it { should be_truthy }
  end

  context 'epub file not exists' do
    before(:all) do
      remove_book
      chdir_to_fixtures
      silence { `softcover new book --polytex` }
      chdir_to_book
    end

    after(:all) { remove_book }

    it 'should raise SystemExit error' do
      expect { silence { Softcover::Commands::EpubValidator.validate! } }.to raise_error(SystemExit)
    end
  end
end

