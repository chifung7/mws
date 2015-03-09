require 'nokogiri'

module Mws::Apis::Feeds

  class PriceListing

    attr_reader :sku, :currency, :base, :sale, :min, :min_allowed, :max_allowed

    def initialize(sku, base, options={})
      @sku = sku
      @base = Money.new(base, options[:currency])
      @currency =  @base.currency
      @min = Money.new(options[:min], @currency) if options.include? :min
      @min_allowed = Money.new(options[:min_allowed], @currency) if options.include? :min_allowed
      @max_allowed = Money.new(options[:max_allowed], @currency) if options.include? :max_allowed
      on_sale(options[:sale][:amount], options[:sale][:from], options[:sale][:to]) if options.include? :sale
      validate
    end

    def on_sale(amount, from, to)
      @sale = SalePrice.new Money.new(amount, @currency), from, to
      validate
      self
    end

    def to_xml(name='Price', parent=nil)
      Mws::Serializer.tree name, parent do |xml| 
        xml.SKU @sku
        @base.to_xml 'StandardPrice', xml
        @min.to_xml 'MAP', xml if @min
        @min_allowed.to_xml 'MinimumSellerAllowedPrice', xml if @min_allowed
        @max_allowed.to_xml 'MaximumSellerAllowedPrice', xml if @max_allowed
        @sale.to_xml 'Sale', xml if @sale
      end
    end

    private

    def validate
      if @min
        unless @min.amount < @base.amount
          raise Mws::Errors::ValidationError, "'Base Price' must be greater than 'Minimum Advertised Price'."
        end
        if @sale and @sale.price.amount <= @min.amount
          raise Mws::Errors::ValidationError, "'Sale Price' must be greater than 'Minimum Advertised Price'."
        end
      end

      if @min_allowed
        unless @base.amount >= @min_allowed.amount
          raise Mws::Errors::ValidationError, "'Base Price' must not be less than 'Minimum Allowed Price'."
        end
      end

      if @max_allowed
        unless @base.amount <= @max_allowed.amount
          raise Mws::Errors::ValidationError, "'Base Price' must not be greater than 'Maximum Allowed Price'."
        end
      end
    end

  end

end
