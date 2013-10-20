require 'spec_helper'

describe Polytexnic::Mathjax do

  subject(:mathjax) { Polytexnic::Mathjax }
  let(:custom_sty) do
%(\\newcommand{\\foo}{\\ensuremath{x}}
\\newcommand{\\bar}[1]{\\textbf{#1}}
)
  end


  context '#config' do

    let(:polytex)    { 'PolyTeX:    "Poly{\\\\TeX}"' }
    let(:polytexnic) { 'PolyTeXnic: "Poly{\\\\TeX}nic"' }

    it "should not raise an error" do
      expect { mathjax.config }.not_to raise_error
    end

    it "should include the default macros" do
      expect(mathjax.config).to include polytex
      expect(mathjax.config).to include polytexnic
    end

    context "with a custom.sty" do

      before { File.stub(:read).and_return(custom_sty) }

      it "should include the custom macros" do
        expect(mathjax.config).to include 'foo: "{x}"'
        expect(mathjax.config).to include 'bar: ["\\\\textbf{#1}", 1]'
      end
    end
  end

  context '#escaped_config' do
    let(:polytex)    { 'PolyTeX:    "Poly{\\\\\\\\TeX}"' }
    let(:polytexnic) { 'PolyTeXnic: "Poly{\\\\\\\\TeX}nic"' }

    it "should include the default macros" do
      expect(mathjax.escaped_config).to include polytex
      expect(mathjax.escaped_config).to include polytexnic
    end

    context "with a custom.sty" do

      before { File.stub(:read).and_return(custom_sty) }

      it "should include the custom macros" do
        expect(mathjax.escaped_config).to include 'foo: "{x}"'
        expect(mathjax.escaped_config).to include 'bar: ["\\\\\\\\textbf{#1}", 1]'
      end
    end
  end
end
