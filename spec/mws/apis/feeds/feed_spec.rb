require 'spec_helper'

module Mws::Apis::Feeds

  describe Feed do

    let(:merchant) { 'GSWCJ4UBA31UTJ' }
    let(:message_type) { :image }

    context '.new' do

      it 'should require a merchant identifier' do
        expect { Feed.new(nil, message_type) }.to raise_error Mws::Errors::ValidationError,
          'Merchant identifier is required.'
      end

      it 'should require a valid message type' do
        expect { Feed.new(merchant, nil) }.to raise_error Mws::Errors::ValidationError,
          'A valid message type is required.'
      end

      it 'shoud default purge and replace to false' do
        expect(Feed.new(merchant, message_type).purge_and_replace).to be false
      end

      it 'should accept overrides to purge and replace' do
        expect(Feed.new(merchant, message_type, true).purge_and_replace).to be true
      end

      it 'should accept a block to append messages to the feed' do
        feed = Feed.new(merchant, message_type) do
          message ImageListing.new('1', 'http://foo.com/bar.jpg'), :delete
          message ImageListing.new('1', 'http://bar.com/foo.jpg')
        end
        expect(feed.messages.size).to eq(2)
        first = feed.messages.first
        expect(first.id).to eq(1)
        expect(first.type).to eq(:image)
        expect(first.operation_type).to eq(:delete)
        expect(first.resource).to eq(ImageListing.new('1', 'http://foo.com/bar.jpg'))
        second = feed.messages.last
        expect(second.id).to eq(2)
        expect(second.type).to eq(:image)
        expect(second.operation_type).to eq(:update)
        expect(second.resource).to eq(ImageListing.new('1', 'http://bar.com/foo.jpg'))
      end

    end

    context '#to_xml' do

      it 'shoud properly serialize to xml' do
        expected = Nokogiri::XML::Builder.new {
          AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => 'amznenvelope.xsd') {
            Header {
              DocumentVersion '1.01'
              MerchantIdentifier 'GSWCJ4UBA31UTJ'
            }
            MessageType 'ProductImage'
            PurgeAndReplace false
            Message {
              MessageID 1
              OperationType 'Delete'
              ProductImage {
                SKU 1
                ImageType 'Main'
                ImageLocation 'http://foo.com/bar.jpg'
              }
            }
            Message {
              MessageID 2
              OperationType 'Update'
              ProductImage {
                SKU 1
                ImageType 'Main'
                ImageLocation 'http://bar.com/foo.jpg'
              }
            }
          }
        }.to_xml
        actual = Feed.new(merchant, message_type) do
          message ImageListing.new('1', 'http://foo.com/bar.jpg'), :delete
          message ImageListing.new('1', 'http://bar.com/foo.jpg')
        end.to_xml
        expect(actual).to eq(expected)
      end

    end

  end

end