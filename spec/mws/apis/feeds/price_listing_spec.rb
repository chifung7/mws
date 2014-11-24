require 'spec_helper'

module Mws::Apis::Feeds

  describe PriceListing do

    context '.new' do

      it 'should be able to construct a price with only sku and base price' do
        price = PriceListing.new('987612345', 14.99)
        expect(price.sku).to eq('987612345')
        expect(price.currency).to eq(:usd)
        expect(price.base).to eq(Money.new(14.99, :usd))
        expect(price.min).to be nil
        expect(price.sale).to be nil
      end

      it 'should be able to construct a price with custom currency code' do
        price = PriceListing.new('9876123456', 14.99, currency: :eur)
        expect(price.currency).to eq(:eur)
        expect(price.base).to eq(Money.new(14.99, :eur))
      end

      it 'should be able to construct a price with custom minimum advertised price' do
        price = PriceListing.new('987612345', 14.99, min: 11.99)
        expect(price.min).to eq(Money.new(11.99, :usd))
      end

      it 'should be able to construct a new price with custom sale price' do
        from = 1.day.ago
        to = 4.months.from_now
        price = PriceListing.new('987612345', 14.99, sale: {
          amount: 12.99,
          from: from,
          to: to
        })
        expect(price.sale).to eq(SalePrice.new(Money.new(12.99, :usd), from, to))
      end

      it 'should validate that the base price is less than the minimum advertised price' do
        expect {
          PriceListing.new('987612345', 9.99, min: 10.00)
        }.to raise_error Mws::Errors::ValidationError, "'Base Price' must be greater than 'Minimum Advertised Price'."
      end

      it 'should validate that the sale price is less than the minimum advertised price' do
        expect {
          PriceListing.new('987612345', 14.99, min: 10.00).on_sale(9.99, 1.day.ago, 4.months.from_now)
        }.to raise_error Mws::Errors::ValidationError, "'Sale Price' must be greater than 'Minimum Advertised Price'."
      end

    end

    context '#on_sale' do

      it 'should provide a nicer syntax for specifying the sale price' do
        from = 1.day.ago
        to = 4.months.from_now
        price = PriceListing.new('987612345', 14.99).on_sale(12.99, from, to)
        expect(price.sale).to eq(SalePrice.new(Money.new(12.99, :usd)  , from, to))
      end

    end

    context '#to_xml' do

      it 'should properly serialize to XML' do
        from = 1.day.ago
        to = 4.months.from_now
        price = PriceListing.new('987612345', 14.99, currency: :eur, min: 10.99).on_sale(12.99, from, to)
        expected = Nokogiri::XML::Builder.new do
          Price {
            SKU '987612345'
            StandardPrice '14.99', currency: 'EUR'
            MAP '10.99', currency: 'EUR'
            Sale {
              StartDate from.iso8601
              EndDate to.iso8601
              SalePrice '12.99', currency: 'EUR'
            }
          }
        end.doc.root.to_xml
        expect(price.to_xml).to eq(expected)
      end

    end

  end

end