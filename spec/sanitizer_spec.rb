require 'spec_helper'
require 'softcover/sanitizer'

describe Softcover::Sanitizer do
  context "malicious html" do
    let(:html) { "<div onclick='alert(document.cookie)'></div>"}

    it "cleans xss vectors" do
      expect(subject.clean(html)).to eq "<div></div>"
    end
  end

  context "safe html" do
    let(:html) do Nokogiri::HTML.fragment(<<-EOS
        <div id="a" class="b"></div>
        <div data-tralics-id="c" data-number="d" data-chapter="e"></div>
        <a id="a" class="b" href="c"></a>
        <span id="a" class="b" style="c"></span>
        <ol id="a" class="b"></ol>
        <ul id="a" class="b"></ul>
        <li id="a" class="b"></li>
        <sup id="a" class="b"></sup>
        <h1 id="a" class="b"></h1>
        <h2 id="a" class="b"></h2>
        <h3 id="a" class="b"></h3>
        <h4 id="a" class="b"></h4>
        <img id="a" class="b" src="c" alt="d" />
        <em id="a" class="b"></em>
      EOS
      ).to_xhtml
    end

    it "allows class and id" do
      expect(subject.clean(html)).to match html
    end
  end
end
