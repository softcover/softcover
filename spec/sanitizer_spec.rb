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
    let(:html) do <<-EOS
        <div id="a" class="b"></div>
        <div data-tralics-id="c" data-number="d" data-chapter="e"></div>
        <a id="b" class="b" href="c"></a>
        <span id="c" class="b" style="color:white"></span>
        <ol id="d" class="b"></ol>
        <ul id="e" class="b">
        <li id="f" class="b">
        </li>
        </ul>
        <sup id="g" class="b"></sup>
        <h1 id="h" class="b"></h1>
        <h2 id="i" class="b"></h2>
        <h3 id="j" class="b"></h3>
        <h4 id="k" class="b"></h4>
        <img id="l" class="b" src="c" alt="d">
        <em id="m" class="b"></em>
      EOS
    end

    it "allows class and id" do
      expect(subject.clean(html)).to match html
    end
  end
end
