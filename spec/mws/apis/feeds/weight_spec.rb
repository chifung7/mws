require 'spec_helper'

module Mws::Apis::Feeds

  describe Weight do

    context '.new' do

      it 'should default to pounds' do
        weight = Weight.new 40
        expect(weight.amount).to eq(40)
        expect(weight.unit).to eq(:pounds)
      end

      it 'should accept a valid unit override' do
        weight = Weight.new 0, :ounces
        expect(weight.amount).to eq(0)
        expect(weight.unit).to eq(:ounces)
      end

      it 'should validate the unit override' do
        expect {
          Weight.new 50, :cent
        }.to raise_error Mws::Errors::ValidationError, "Invalid unit of measure 'cent'"
      end

    end

    context '#to_xml' do

      it 'should properly serialize to XML' do
        weight = Weight.new 25, :grams
        expected = Nokogiri::XML::Builder.new do
          Weight 25, unitOfMeasure: 'GR'
        end.doc.root.to_xml
        expect(weight.to_xml).to eq(expected)
      end

    end

  end
  
end