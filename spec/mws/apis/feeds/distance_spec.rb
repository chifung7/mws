require 'spec_helper'

module Mws::Apis::Feeds

  describe Distance do

    context '.new' do

      it 'should default to feet' do
        distance = Distance.new 40
        expect(distance.amount).to eq(40)
        expect(distance.unit).to eq(:feet)
      end

      it 'should accept a valid unit override' do
        distance = Distance.new 0, :meters
        expect(distance.amount).to eq(0)
        expect(distance.unit).to eq(:meters)
      end

      it 'should validate the unit override' do
        expect {
          Distance.new 40, :acres
        }.to raise_error Mws::Errors::ValidationError, "Invalid unit of measure 'acres'"
      end

    end

    context '#to_xml' do

      it 'should properly serialize to XML' do
        distance = Distance.new 25, :inches
        expected = Nokogiri::XML::Builder.new do
          Distance 25, unitOfMeasure: 'inches'
        end.doc.root.to_xml
        expect(distance.to_xml).to eq(expected)
      end

    end

  end
  
end