require 'spec_helper'

describe Softcover::Mathjax do

  subject(:mathjax) { Softcover::Mathjax }

  let(:custom_sty) do
%(\\newcommand{\\foo}{\\ensuremath{x}}
\\newcommand{\\bar}[1]{\\textbf{#1}}
% \\newcommand{\\baz}{quux}
)
  end
  let(:baz) { 'quux' }

  shared_examples "config" do

    it "should include the default macros" do
      expect(config).to include polytex
      expect(config).to include polytexnic
    end

    context "with a custom.sty" do

      before { allow(Softcover).to receive(:custom_styles).and_return(custom_sty) }

      it "should include the custom macros" do
        expect(config).to include foo
        expect(config).to include bar
      end

      it "should not include a commented-out macro" do
        expect(config).not_to include baz
      end
    end
  end

  context '#config' do

    let(:polytex)    { 'PolyTeX:    "Poly{\\\\TeX}"' }
    let(:polytexnic) { 'PolyTeXnic: "Poly{\\\\TeX}nic"' }
    let(:foo)        { '"foo": "{x}"' }
    let(:bar)        { '"bar": ["\\\\textbf{#1}", 1]' }
    let(:config)     { mathjax.config }

    it "should not raise an error" do
      expect { config }.not_to raise_error
    end

    it_should_behave_like "config"
  end

  context '#escaped_config' do
    let(:polytex)    { 'PolyTeX:    "Poly{\\\\\\\\TeX}"' }
    let(:polytexnic) { 'PolyTeXnic: "Poly{\\\\\\\\TeX}nic"' }
    let(:foo)        { '"foo": "{x}"' }
    let(:bar)        { '"bar": ["\\\\\\\\textbf{#1}", 1]' }
    let(:config)     { mathjax.escaped_config }

    it_should_behave_like "config"
  end
end
