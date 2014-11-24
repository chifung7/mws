require 'spec_helper'

module Mws::Apis::Feeds 

  class Temperature < Measurement

    Unit = Mws::Enum.for(
      fahrenheit: 'Fahrenheight',
      celcius: 'Celcius',
      kelvin: 'Kelvin'
    )

    def initialize(amount, unit=:fahrenheit)
      super amount, unit
    end

  end

  describe Measurement do

    context '.new' do

      it 'should default to fahrenheit' do
        temp = Temperature.new 40
        expect(temp.amount).to eq(40)
        expect(temp.unit).to eq(:fahrenheit)
      end

      it 'should accept a valid unit override' do
        temp = Temperature.new 0, :kelvin
        expect(temp.amount).to eq(0)
        expect(temp.unit).to eq(:kelvin)
      end

      it 'should validate the unit override' do
        expect {
          Temperature.new 40, :ounces
        }.to raise_error Mws::Errors::ValidationError, "Invalid unit of measure 'ounces'"
      end

    end

    context '#==' do

      it 'should be reflexive' do
        a = Temperature.new 25, :celcius
        expect(a == a).to be true
      end

      it 'should be symmetric' do
        a = Temperature.new 25, :celcius
        b = Temperature.new 25, :celcius
        expect(a == b).to eq(b == a)
      end

      it 'should be transitive' do
        a = Temperature.new 25, :celcius
        b = Temperature.new 25, :celcius
        c = Temperature.new 25, :celcius
        expect(a == c).to eq(a == b && b == c)
      end

      it 'should handle comparison to nil' do
        a = Temperature.new 25, :celcius
        expect(a == nil).to be false
      end

    end

    context '#to_xml' do

      it 'should properly serialize to XML' do
        temp = Temperature.new 25, :celcius
        expected = Nokogiri::XML::Builder.new do
          Temperature 25, unitOfMeasure: 'Celcius'
        end.doc.root.to_xml
        expect(temp.to_xml).to eq(expected)
      end

    end

  end
  
end