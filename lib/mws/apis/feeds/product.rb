module Mws::Apis::Feeds

  class Product

    CategorySerializer = Mws::Serializer.new ce: 'CE', fba: 'FBA', eu_compliance: 'EUCompliance'

    attr_reader :sku

    attr_accessor :standard_product_id, :standard_product_id_type
    attr_accessor :condition
    attr_accessor :tax_code, :msrp, :brand, :manufacturer, :name, :authors, :description, :bullet_points, :item_type
    attr_accessor :item_dimensions, :package_dimensions, :package_weight, :shipping_weight
    attr_accessor :category, :details

    def initialize(sku, &block)
      @sku = sku
      @bullet_points = []

      ProductBuilder.new(self).instance_eval &block if block_given?
      raise Mws::Errors::ValidationError, 'Product must have a category when details are specified.' if @details and @category.nil?
    end

    %w[UPC ASIN ISBN EAN GTIN].each do |t|
      m = t.downcase

      define_method(m) do
        @standard_product_id_type == t ? @standard_product_id : nil        
      end

      define_method("#{m}=") do |pid|
        @standard_product_id_type = pid.nil? ? nil : t
        @standard_product_id = pid
      end
    end

    def to_xml(name='Product', parent=nil)
      Mws::Serializer.tree name, parent do |xml|
        xml.SKU @sku

        xml.StandardProductID {
          xml.Type @standard_product_id_type
          xml.Value @standard_product_id
        } unless @standard_product_id.nil?

        xml.ProductTaxCode @tax_code unless @standard_product_id.nil?

        @condition.to_xml('Condition', xml) unless @condition.nil?

        unless @name.nil? and @authors.nil? and @brand.nil? and @description.nil? and @item_dimensions.nil? and
            @package_weight.nil? and @shipping_weight.nil? and @msrp.nil? and @manufacture.nil? and @item_type.nil?
          xml.DescriptionData {
            xml.Title @name unless @name.nil?
            unless @authors.nil?
              @authors.each do |author|
                xml.Author author
              end
            end
            xml.Brand @brand  unless @brand.nil?
            xml.Description @description  unless @description.nil?
            bullet_points.each do | bullet_point |
              xml.BulletPoint bullet_point
            end
            xml.ItemType @item_type unless @item_type.nil?

            @item_dimensions.to_xml('ItemDimensions', xml) unless @item_dimensions.nil?
            @package_dimensions.to_xml('PackageDimensions', xml) unless @item_dimensions.nil?

            @package_weight.to_xml('PackageWeight', xml) unless @package_weight.nil?
            @shipping_weight.to_xml('ShippingWeight', xml) unless @shipping_weight.nil?

            @msrp.to_xml 'MSRP', xml unless @msrp.nil?

            xml.Manufacturer @manufacturer unless @manufacturer.nil?
          }
        end

        unless @details.nil?
          xml.ProductData {
            CategorySerializer.xml_for @category, {product_type: @details}, xml
          }
        end
      end
    end

    class DelegatingBuilder

      def initialize(delegate)
        @delegate = delegate
      end

      def method_missing(method, *args, &block)
        @delegate.send("#{method}=", *args, &block) if @delegate.respond_to? "#{method}="
      end
    end

    class ProductBuilder < DelegatingBuilder

      def initialize(product)
        super product
        @product = product
      end

      def condition(&block)
        @product.condition = Condition.new
        ConditionBuilder.new(@product.condition).instance_eval &block if block_given?
      end

      def msrp(amount, currency)
        @product.msrp = Money.new amount, currency
      end

      def item_dimensions(&block)
        @product.item_dimensions = Dimensions.new
        DimensionsBuilder.new(@product.item_dimensions).instance_eval &block if block_given?
      end

      def package_dimensions(&block)
        @product.package_dimensions = Dimensions.new
        DimensionsBuilder.new(@product.package_dimensions).instance_eval &block if block_given?
      end

      def package_weight(value, unit=nil)
        @product.package_weight = Weight.new(value, unit)
      end

      def shipping_weight(value, unit=nil)
        @product.shipping_weight = Weight.new(value, unit)
      end

      def bullet_point(bullet_point)
        @product.bullet_points << bullet_point
      end

      def details(details=nil, &block)
        @product.details = details || {}
        DetailBuilder.new(@product.details).instance_eval &block if block_given?
      end

    end

    class Condition
      Type = Mws::Enum.for(new: 'New',
                           like_new: 'UsedLikeNew',
                           very_good: 'UsedVeryGood',
                           good: 'UsedGood',
                           acceptable: 'UsedAcceptable',
                           collectible_like_new: 'CollectibleLikeNew',
                           collectible_very_good: 'CollectibleVeryGood',
                           collectible_good: 'CollectibleGood',
                           collectible_acceptable: 'CollectibleAcceptable',
                           club: 'Club')

      attr_accessor :type, :note
      def type=(t)
        t.nil? or Type.for(t) or raise Mws::Errors::ValidationError, 'Invalid Condition Type #{t}.'
        @type = t
      end

      def note=(n)
        n.nil? or n.length <= 2000 or raise Mws::Errors::ValidationError, 'Condition Note too long: #{n}'
        @note = n
      end

      def to_xml(name='Condition', parent=nil)
        Mws::Serializer.tree name, parent do |xml|
          t = Type.for(@type || :new)
          xml.ConditionType t.val
          xml.ConditionNote @note
        end
      end
    end

    class ConditionBuilder
      def initialize(condition)
        @condition = condition
      end

      def type(t)
        @condition.type = t
      end

      def note(n)
        @condition.note = n
      end
    end

    class Dimensions

      attr_accessor :length, :width, :height, :weight

      def to_xml(name='Dimensions', parent=nil)
        Mws::Serializer.tree name, parent do |xml|
          @length.to_xml 'Length', xml unless @length.nil?
          @width.to_xml 'Width', xml unless @width.nil?
          @height.to_xml 'Height', xml unless @height.nil?
          @weight.to_xml 'Weight', xml unless @weight.nil?
        end
      end

    end

    class DimensionsBuilder

      def initialize(dimensions)
        @dimensions = dimensions
      end

      def length(value, unit=nil)
        @dimensions.length = Distance.new(value, unit)
      end

      def width(value, unit=nil)
        @dimensions.width = Distance.new(value, unit)
      end

      def height(value, unit=nil)
        @dimensions.height = Distance.new(value, unit)
      end

      def weight(value, unit=nil)
        @dimensions.weight = Weight.new(value, unit)
      end
    end

    class DetailBuilder

      def initialize(details)
        @details = details
      end

      def as_distance(amount, unit=nil)
        Distance.new amount, unit
      end

      def as_weight(amount, unit=nil)
        Weight.new amount, unit
      end

      def as_money(amount, currency=nil)
        Money.new amount, currency
      end            

      def method_missing(method, *args, &block)
        if block_given?
          @details[method] = {}
          DetailBuilder.new(@details[method]).instance_eval(&block)
        elsif args.length > 0
          @details[method] = args[0]
        end
      end

    end

  end
end
