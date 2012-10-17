require 'nokogiri'

module Mws::Apis::Feeds

  class Price

    attr_reader :amount, :currency

    def initialize(amount, currency)
      @amount = amount
      @currency = currency
    end

    def ==(other)
      return true if equal? other
      return false unless other.class == self.class
      @amount == other.amount and @currency == other.currency
    end

    def to_xml(name='Price', parent=nil)
      if parent
        parent.send(name, '%.2f' % @amount, currency: @currency)
        parent.to_xml
      else
        Nokogiri::XML::Builder.new do | xml |
          xml.send(name, '%.2f' % @amount, currency: @currency)
        end.to_xml
      end
    end

  end

end