# encoding=utf-8

RSpec::Matchers.define :exist do
  match do |filename|
    expect(File.exist?(filename)).to be_truthy
  end
end
