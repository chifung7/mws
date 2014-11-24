require 'spec_helper'

module Mws::Apis::Feeds

  describe Shipping do

    context '.new' do

      it 'should require non-nil sku' do
        expect { Shipping.new(nil) }.to raise_error Mws::Errors::ValidationError, 
          'SKU is required.'
      end

      it 'should require a non-empty sku' do
        expect { Shipping.new('') }.to raise_error Mws::Errors::ValidationError, 
          'SKU is required.'
      end

      it 'should require a sku that is not all whitespace' do
        expect { Shipping.new('   ') }.to raise_error Mws::Errors::ValidationError, 
          'SKU is required.'
      end

      it 'should accept a valid value for sku' do
        expect(Shipping.new('987612345').sku).to eq('987612345')
      end

      it 'should accept a block to associate shipping option overrides' do
        shipping = Shipping.new('987612345') do
          replace 4.99, :usd, :continental_us, :standard, :street
        end
        expect(shipping.sku).to eq('987612345')
        expect(shipping.options.size).to eq(1)
        override = shipping.options.first
        expect(override.amount).to eq(Money.new(4.99, :usd))
        expect(override.option.region).to eq(:continental_us)
        expect(override.option.speed).to eq(:standard)
        expect(override.option.variant).to eq(:street)
      end

    end

    context '#to_xml' do
      shipping = Shipping.new('987612345') do
        unrestricted :continental_us, :standard
        restricted :continental_us, :expedited
        adjust 19.99, :usd, :continental_us, :two_day, :street
        replace 29.99, :usd, :continental_us, :one_day, :street
      end
      expected = Nokogiri::XML::Builder.new do
        Override {
          SKU '987612345'
          ShippingOverride {
            ShipOption 'Std Cont US Street Addr'
            IsShippingRestricted 'false'
          }
          ShippingOverride {
            ShipOption 'Exp Cont US Street Addr'
            IsShippingRestricted 'true'
          }
          ShippingOverride {
            ShipOption 'Second'
            Type 'Additive'
            ShipAmount '19.99', currency: 'USD'
          }
          ShippingOverride {
            ShipOption 'Next'
            Type 'Exclusive'
            ShipAmount '29.99', currency: 'USD'
          }
        }
      end.doc.root.to_xml
      shipping.to_xml.should == expected
    end

  end

end