require 'spec_helper'
require 'nokogiri'

module Mws::Apis::Feeds

  describe Product do 

    context '.new' do

      it 'should require a sku' do
        expect { Product.new }.to raise_error ArgumentError 

        sku = '12343533'
        expect(Product.new(sku).sku).to eq(sku)
      end

      it 'should support product builder block initialization' do
        capture = nil
        product = Product.new('123431') do 
          capture = self
        end
        expect(capture).to be_an_instance_of Product::ProductBuilder
      end

      it 'should support building with upc, tax code, brand, manufacture and name' do
        product = Product.new('12324') do
          upc '4321'
          tax_code 'GEN_TAX_CODE'
          brand 'Test Brand'
          manufacturer 'Test manufacture'
          name 'Test Product'
          authors ['Foo', 'Bar']
        end

        expect(product.upc).to eq('4321')
        expect(product.tax_code).to eq('GEN_TAX_CODE')
        expect(product.brand).to eq('Test Brand')
        expect(product.manufacturer).to eq('Test manufacture')
        expect(product.name).to eq('Test Product')
        expect(product.authors).to eq(['Foo', 'Bar'])
      end

      it 'should support building with isbn' do
        product = Product.new('12324') do
          isbn '9781888363821'
        end
        expect(product.isbn).to eq('9781888363821')
      end

      it 'should support condition type and note' do
        product = Product.new('12324') do
          isbn '9781888363821'
          condition do
            type :like_new
            note 'Like New. Never Used'
          end
        end
        expect(product.condition.type).to eq(:like_new)
        expect(product.condition.note).to eq('Like New. Never Used')
      end

      it 'should support condition note and default to :new type' do
        product = Product.new('12324') do
          isbn '9781888363821'
          condition do
            note 'Brand New'
          end
        end
        expect(product.condition.type).to be_nil
        expect(product.condition.note).to eq('Brand New')
      end

      it 'should support building with msrp' do
        product = Product.new('12324') do
          msrp 10.99, :usd
        end

        expect(product.msrp.amount).to eq(10.99)
        expect(product.msrp.currency).to eq(:usd)
      end

      it 'should support building with item dimensions' do
        product = Product.new('12324') do
          item_dimensions {
            length 2, :feet
            width 3, :inches
            height 1, :meters
            weight 4, :pounds
          }
        end

        expect(product.item_dimensions.length).to eq(Distance.new(2, :feet))
        expect(product.item_dimensions.width).to eq(Distance.new(3, :inches))
        expect(product.item_dimensions.height).to eq(Distance.new(1, :meters))
        expect(product.item_dimensions.weight).to eq(Weight.new(4, :pounds))
      end

      it 'should support building with package dimensions' do
        product = Product.new('12324') do
          package_dimensions {
            length 2, :feet
            width 3, :inches
            height 1, :meters
            weight 4, :pounds
          }
        end

        expect(product.package_dimensions.length).to eq(Distance.new(2, :feet))
        expect(product.package_dimensions.width).to eq(Distance.new(3, :inches))
        expect(product.package_dimensions.height).to eq(Distance.new(1, :meters))
        expect(product.package_dimensions.weight).to eq(Weight.new(4, :pounds))
      end
    
      it 'should require valid package and shipping dimensions' do
        capture = self
        product = Product.new('12324') do
          package_dimensions {
            capture.expect { length 2, :foots }.to capture.raise_error Mws::Errors::ValidationError
            capture.expect { width 2, :decades }.to capture.raise_error Mws::Errors::ValidationError
            capture.expect { height 1, :miles }.to capture.raise_error Mws::Errors::ValidationError
            capture.expect { weight 1, :stone }.to capture.raise_error Mws::Errors::ValidationError
          }
        end
      end

      it 'should support building with description and bullet points' do
        product = Product.new('12343') do
          description 'This is a test product description.'
          bullet_point 'Bullet Point 1'
          bullet_point 'Bullet Point 2'
          bullet_point 'Bullet Point 3'
          bullet_point 'Bullet Point 4'
        end
        expect(product.description).to eq('This is a test product description.')
        expect(product.bullet_points.length).to eq(4)
        expect(product.bullet_points[0]).to eq('Bullet Point 1')
        expect(product.bullet_points[1]).to eq('Bullet Point 2')
        expect(product.bullet_points[2]).to eq('Bullet Point 3')
        expect(product.bullet_points[3]).to eq('Bullet Point 4')
      end


      it 'should support building with package and shipping weight' do
        product = Product.new('12343') do
          package_weight 3, :pounds
          shipping_weight 4, :ounces
        end

        expect(product.package_weight).to eq(Weight.new(3, :pounds))
        expect(product.shipping_weight).to eq(Weight.new(4, :ounces))
      end

      it 'should support building with product details' do
        product = Product.new '12343' do
          category :ce
          details {
            value 'some value'
            nested {
              foo 'bar'
              nested {
                baz 'bahhh'
              }
            }
          }
        end

        expect(product.details).not_to be nil
        expect(product.details[:value]).to eq('some value')
        expect(product.details[:nested][:foo]).to eq('bar')
        expect(product.details[:nested][:nested][:baz]).to eq('bahhh')
      end

      it 'should require a category when product details are specified' do
        expect {
          Product.new '12343' do
            details {
              value 'some value'
              nested {
                foo 'bar'
                nested {
                  baz 'bahhh'
                }
              }
            }
          end
        }.to raise_error Mws::Errors::ValidationError, 'Product must have a category when details are specified.'
      end

    end

    context '#to_xml' do

      it 'should create xml for standard attributes' do

        expected = Nokogiri::XML::Builder.new do
          Product {
            SKU '12343'
            StandardProductID {
              Type 'UPC'
              Value '432154321'
            }
            ProductTaxCode 'GEN_TAX_CODE'
            Condition {
              ConditionType 'UsedLikeNew'
              ConditionNote 'Like New. Never Used'
            }
            DescriptionData {
              Title 'Test Product'
              Author 'Foo'
              Author 'Bar'
              Brand 'Test Brand'
              Description 'Some product'
              BulletPoint 'Bullet Point 1'
              BulletPoint 'Bullet Point 2'
              BulletPoint 'Bullet Point 3'
              BulletPoint 'Bullet Point 4'
              ItemDimensions {
                Length 2, unitOfMeasure: 'feet'
                Width 3, unitOfMeasure: 'inches'
                Height 1, unitOfMeasure: 'meters'
                Weight 4, unitOfMeasure: 'LB'
              }
              PackageDimensions {
                Length 2, unitOfMeasure: 'feet'
                Width 3, unitOfMeasure: 'inches'
                Height 1, unitOfMeasure: 'meters'
                Weight 4, unitOfMeasure: 'LB'
              }
              PackageWeight 2, unitOfMeasure: 'LB'
              ShippingWeight 3, unitOfMeasure: 'MG'
              MSRP 19.99, currency: 'USD'
              Manufacturer 'Test manufacture'
            }
          }
        end.doc.root.to_xml

        expect(expected).to eq(Product.new('12343') do
          upc '432154321'
          condition {
            type :like_new
            note 'Like New. Never Used'
          }
          tax_code 'GEN_TAX_CODE'
          brand 'Test Brand'
          name 'Test Product'
          authors ['Foo', 'Bar']
          description 'Some product'
          msrp 19.99, 'USD'
          manufacturer 'Test manufacture'
          bullet_point 'Bullet Point 1'
          bullet_point 'Bullet Point 2'
          bullet_point 'Bullet Point 3'
          bullet_point 'Bullet Point 4'
          item_dimensions {
            length 2, :feet
            width 3, :inches
            height 1, :meters
            weight 4, :pounds
          }
          package_dimensions {
            length 2, :feet
            width 3, :inches
            height 1, :meters
            weight 4, :pounds
          }
          package_weight 2, :pounds
          shipping_weight 3, :miligrams
        end.to_xml)
        
      end

      it 'should create xml for product default to new condition' do
        expected = Nokogiri::XML::Builder.new do
          Product {
            SKU '12343'
            StandardProductID {
              Type 'ASIN'
              Value '4321543210'
            }
            ProductTaxCode 'GEN_TAX_CODE'
            Condition {
              ConditionType 'New'
              ConditionNote 'Brand New'
            }
          }
        end.doc.root.to_xml

        expect(expected).to eq(Product.new('12343') do
          asin '4321543210'
          condition {
            note 'Brand New'
          }
          tax_code 'GEN_TAX_CODE'
        end.to_xml)
      end

      it 'should create xml for product details' do
        expected = Nokogiri::XML::Builder.new do
          Product {
            SKU '12343'
            #DescriptionData {}
            ProductData {
              CE {
                ProductType {
                  CableOrAdapter {
                    CableLength 6, unitOfMeasure: 'feet'
                    CableWeight 6, unitOfMeasure: 'OZ'
                    CostSavings '6.99', currency: 'USD'
                  }
                }
              }
            }
          }
        end.doc.root.to_xml

        expect(expected).to eq(Product.new('12343') do 
          category :ce
          details {
            cable_or_adapter {
              cable_length as_distance 6, :feet
              cable_weight as_weight 6, :ounces
              cost_savings as_money 6.99, :usd
            }    
          }
        end.to_xml)
      end

    end

  end

end
