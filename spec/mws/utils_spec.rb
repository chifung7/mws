require 'spec_helper'

module Mws

  module Foo

    module Bar

      class Baz

        def initialize(quk)
          @quk = quk
        end

      end

      class Quk

        def initialize(bar)
          @bar = bar
        end

      end

    end

  end

  describe Utils do

    context '.camelize' do

      it 'should properly camelize nil' do
        expect(Utils.camelize(nil)).to be nil
        expect(Utils.camelize(nil, false)).to be nil
      end

      it 'should properly camelize the empty string' do
        expect(Utils.camelize('')).to eq('')
        Utils.camelize('', false) == ''
      end

      it 'should trim whitespace from the string' do
        expect(Utils.camelize('   ')).to eq('')
        Utils.camelize('   ', false) == ''
        expect(Utils.camelize('  foo_bar_baz    ')).to eq('FooBarBaz')
        expect(Utils.camelize(' foo_bar_baz  ', false)).to eq('fooBarBaz')
      end

      it 'should properly camelize single segment names' do
        expect(Utils.camelize('foo')).to eq('Foo')
        expect(Utils.camelize('foo', false)).to eq('foo')
      end

      it 'should properly camelize multi-segment names' do
        expect(Utils.camelize('foo_bar_baz')).to eq('FooBarBaz')
        expect(Utils.camelize('foo_bar_baz', false)).to eq('fooBarBaz')
      end

      it 'should properly camelize mixed case multi-segment names' do
        expect(Utils.camelize('fOO_BAR_BAZ')).to eq('FooBarBaz')
        expect(Utils.camelize('fOO_BAR_BAZ', false)).to eq('fooBarBaz')
      end

    end

    context '.underscore' do

      it 'should properly underscore nil' do
        expect(Utils.underscore(nil)).to be nil
      end

      it 'should properly camelize the empty string' do
        expect(Utils.underscore('')).to eq('')
      end

      it 'should trim whitespace from the string' do
        expect(Utils.underscore('   ')).to eq('')
        expect(Utils.underscore('  FooBarBaz    ')).to eq('foo_bar_baz')
      end

      it 'should properly underscore single-segment names' do
        expect(Utils.underscore('Foo')).to eq('foo')
        expect(Utils.underscore('foo')).to eq('foo')
      end

      it 'should properly underscore multi-segment names' do
        expect(Utils.underscore('FooBarBaz')).to eq('foo_bar_baz')
      end

    end

    context '.uri_escape' do

      {
        ' ' => '20',
        '"' => '22',
        '#' => '23',
        '$' => '24',
        '%' => '25',
        '&' => '26',
        '+' => '2B',
        ',' => '2C',
        '/' => '2F',
        ':' => '3A',
        ';' => '3B',
        '<' => '3C',
        '=' => '3D',
        '>' => '3E',
        '?' => '3F',
        '@' => '40',
        '[' => '5B',
        '\\' => '5C',
        ']' => '5D',
        '^' => '5E',
        '{' => '7B',
        '|' => '7C',
        '}' => '7D'
      }.each do | key, value |
        it "should properly escape '#{key}' as '%#{value}'" do
          expect(Utils.uri_escape("foo#{key}bar")).to eq("foo%#{value}bar")
        end
      end

    end

    context '.alias' do

      before(:all) do
        Utils.alias Mws, Mws::Foo::Bar, :Baz, :Quk
      end

      it 'should create aliases of the specified constants' do
        expect(Mws::Baz).to eq(Mws::Foo::Bar::Baz)
        expect(Mws::Quk).to eq(Mws::Foo::Bar::Quk)
      end

      it 'should create constructor shortcuts' do
        expect(Mws::Baz('quk')).to be_a Mws::Foo::Bar::Baz
        expect(Mws::Quk('baz')).to be_a Mws::Foo::Bar::Quk
      end

    end

  end

end