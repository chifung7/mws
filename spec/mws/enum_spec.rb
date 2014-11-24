require 'spec_helper'

module Mws

  describe Enum do

    before(:all) do
      @options = {
        pending: 'Pending',
        unshipped: [ 'Unshipped', 'PartiallyShipped' ],
        shipped: 'Shipped',
        invoice_unconfirmed: 'InvoiceUnconfirmed',
        cancelled: 'Cancelled',
        unfulfillable: 'Unfulfillable'
      }

      OrderStatus = Enum.for @options
    end

    let (:options) { @options }

    it 'should not allow instance creation via new' do
      expect { Enum.new }.to raise_error NoMethodError
    end

    context '.for' do

      it 'should construct a pseudo-constant accessor for each provided symbol' do
        options.each do | key, value |
          expect(OrderStatus.send(key.to_s.upcase.to_sym)).not_to be nil
        end
      end

      it 'should not share pseudo-constants between enumeration instances' do
        EnumOne = Enum.for( foo: 'Foo', bar: 'Bar', baz: 'Baz' )
        EnumTwo = Enum.for( bar: 'BAR', baz: 'BAZ', quk: 'QUK' )
        expect { EnumOne.QUK }.to raise_error NoMethodError
        expect { EnumTwo.FOO }.to raise_error NoMethodError
        expect(EnumOne.BAR).not_to eq(EnumTwo.BAR)
      end

    end

    context '.sym_reader' do

      class HasEnumAttrs

        EnumOne = Enum.for( foo: 'Foo', bar: 'Bar', baz: 'Baz' )

        EnumTwo = Enum.for( bar: 'BAR', baz: 'BAZ', quk: 'QUK' )

        Enum.sym_reader self, :one, :two

        def initialize(one, two)
          @one = EnumOne.for(one)
          @two = EnumTwo.for(two)
        end

      end

      it 'should synthesize a attr_reader that exposes an enum entry as a symbol' do
        it = HasEnumAttrs.new(:foo, :quk)
        expect(it.send(:instance_variable_get, '@one')).to eq(HasEnumAttrs::EnumOne.FOO)
        expect(it.one).to eq(:foo)
        expect(it.send(:instance_variable_get, '@two')).to eq(HasEnumAttrs::EnumTwo.QUK)
        expect(it.two).to eq(:quk)
      end

      it 'should synthesize attr_readers that are null safe' do
        it = HasEnumAttrs.new(:quk, :foo)
        expect(it.one).to be nil
        expect(it.two).to be nil
      end

    end

    context '#for' do

      it 'should be able to find an enum entry from a symbol' do
        expect(OrderStatus.for(:pending)).to eq(OrderStatus.PENDING)
      end

      it 'should be able to find an enum entry from a string' do
        expect(OrderStatus.for('Pending')).to eq(OrderStatus.PENDING)
      end

      it 'should be able to find an enum entry from an enum entry' do
        expect(OrderStatus.for(OrderStatus.PENDING)).to eq(OrderStatus.PENDING)
      end
      
    end

    context '#sym' do

      it 'should return nil for nil value' do
        expect(OrderStatus.sym(nil)).to be nil
      end

      it 'should return nil for an unknown value' do
        expect(OrderStatus.sym('UnknownValue')).to be nil
      end

      it 'should provide the symbol for a given value' do
        expect(OrderStatus.sym('Pending')).to eq(:pending)
        expect(OrderStatus.sym('Unshipped')).to eq(:unshipped)
        expect(OrderStatus.sym('PartiallyShipped')).to eq(:unshipped)
        expect(OrderStatus.sym('Shipped')).to eq(:shipped)
        expect(OrderStatus.sym('Cancelled')).to eq(:cancelled)
        expect(OrderStatus.sym('Unfulfillable')).to eq(:unfulfillable)
      end

    end

    context '#val' do

      it 'should return nil for nil symbol' do
        expect(OrderStatus.val(nil)).to be nil
      end

      it 'should return nil for an unknown sumbol' do
        expect(OrderStatus.val(:unknown)).to be nil
      end

      it 'should provide the value for a given symbol' do
        expect(OrderStatus.val(:pending)).to eq('Pending')
        expect(OrderStatus.val(:unshipped)).to eq([ 'Unshipped', 'PartiallyShipped' ])
        expect(OrderStatus.val(:shipped)).to eq('Shipped')
        expect(OrderStatus.val(:cancelled)).to eq('Cancelled')
        expect(OrderStatus.val(:unfulfillable)).to eq('Unfulfillable')
      end

    end

    context '#syms' do

      it 'should provide the set of symbols' do
        expect(OrderStatus.syms).to eq(options.keys)
      end

    end

    context '#vals' do

      it 'should provide the list of values' do
        expect(OrderStatus.vals).to eq(options.values.flatten)
      end

    end

    it 'should be able to provide a symbol for an entry' do
      expect(OrderStatus.PENDING.sym).to eq(:pending)
    end

    it 'should be able to provide a value for an enum entry' do
      expect(OrderStatus.PENDING.val).to eq('Pending')
    end

    it 'should be able to handle multivalued enum entries' do
      expect(OrderStatus.for(:unshipped)).to eq(OrderStatus.UNSHIPPED)
      expect(OrderStatus.for('Unshipped')).to eq(OrderStatus.UNSHIPPED)
      expect(OrderStatus.for('PartiallyShipped')).to eq(OrderStatus.UNSHIPPED)
    end
    
  end

end
