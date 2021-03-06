require 'spec_helper'

module Mws::Apis::Feeds

  class Api
    attr_reader :defaults
  end

  describe Api do

    let(:connection) do
      Mws::Connection.new(
        merchant: 'GSWCJ4UBA31UTJ',
        access: 'AYQAKIAJSCWMLYXAQ6K3', 
        secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
      )
    end

    let(:api) { Api.new(connection) }

    context '.new' do

      it 'should require connection' do
        expect { Api.new(nil) }.to raise_error Mws::Errors::ValidationError, 'A connection is required.'
      end

      it 'should default version to 2009-01-01' do
        expect(api.defaults[:version]).to eq('2009-01-01')
      end

      it 'should initialize a products feed' do
        stub_const(TargetedApi.to_s, class_spy("DoubleTargetedApi"))
        expect(TargetedApi).to receive(:new).with(anything, connection.merchant, :product)
        api = Api.new(connection)
        expect(api.products).not_to be nil
      end

      it 'should initialize an images feed' do
        stub_const(TargetedApi.to_s, class_spy("DoubleTargetedApi"))
        expect(TargetedApi).to receive(:new).with(anything, connection.merchant, :image)
        api = Api.new(connection)
        expect(api.images).not_to be nil
      end

      it 'should initialize a prices feed' do
        stub_const(TargetedApi.to_s, class_spy("DoubleTargetedApi"))
        expect(TargetedApi).to receive(:new).with(anything, connection.merchant, :price)
        api = Api.new(connection)
        expect(api.prices).not_to be nil
      end

      it 'should initialize a shipping feed' do
        stub_const(TargetedApi.to_s, class_spy("DoubleTargetedApi"))
        expect(TargetedApi).to receive(:new).with(anything, connection.merchant, :override)
        api = Api.new(connection)
        expect(api.shipping).not_to be nil
      end

      it 'should initialize an inventory feed' do
        stub_const(TargetedApi.to_s, class_spy("DoubleTargetedApi"))
        expect(TargetedApi).to receive(:new).with(anything, connection.merchant, :inventory)
        api = Api.new(connection)
        expect(api.inventory).not_to be nil
      end

    end

    context '#get' do

      it 'should properly delegate to connection' do
        expect(connection).to receive(:get).with('/', { feed_submission_id: 1 }, { 
          version: '2009-01-01',
          action: 'GetFeedSubmissionResult',
          xpath: 'AmazonEnvelope/Message'
        }).and_return('a_node')
        expect(SubmissionResult).to receive(:from_xml).with('a_node')
        api.get(1)
      end

    end

    context '#submit' do

      it 'should properly delegate to connection' do
        response = double(:response)
        expect(response).to receive(:xpath).with('FeedSubmissionInfo').and_return(['a_result'])
        expect(connection).to receive(:post).with('/', { feed_type: '_POST_INVENTORY_AVAILABILITY_DATA_' }, 'a_body', {
          version: '2009-01-01',
          action: 'SubmitFeed'
        }).and_return(response)
        expect(SubmissionInfo).to receive(:from_xml).with('a_result')
        api.submit 'a_body', feed_type: :inventory
      end

    end

    context '#list' do

      it 'should handle a single submission id' do
        response = double(:response)
        expect(response).to receive(:xpath).with('FeedSubmissionInfo').and_return(['result_one'])
        expect(connection).to receive(:get).with('/', { feed_submission_id: [ 1 ] }, {
          version: '2009-01-01',
          action: 'GetFeedSubmissionList'
        }).and_return(response)
        expect(SubmissionInfo).to receive(:from_xml) { | node | node }.once
        expect(api.list(id: 1)).to eq([ 'result_one' ])
      end

      it 'should handle a multiple submission ids' do
        response = double(:response)
        expect(response).to receive(:xpath).with('FeedSubmissionInfo').and_return([ 'result_one', 'result_two', 'result_three' ])
        expect(connection).to receive(:get).with('/', { feed_submission_id: [ 1, 2, 3 ] }, {
          version: '2009-01-01',
          action: 'GetFeedSubmissionList'
        }).and_return(response)
        expect(SubmissionInfo).to receive(:from_xml) { | node | node }.exactly(3).times
        expect(api.list(ids: [ 1, 2, 3 ])).to eq([ 'result_one', 'result_two', 'result_three' ])
      end

    end

    context '#count' do

      it 'should properly delegate to connection' do
        count = double(:count)
        expect(count).to receive(:text).and_return('5')
        response = double(:response)
        expect(response).to receive(:xpath).with('Count').and_return([ count ])
        expect(connection).to receive(:get).with('/', {}, {
          version: '2009-01-01',
          action: 'GetFeedSubmissionCount'
        }).and_return(response)
        expect(api.count).to eq(5)
      end

    end

  end

  describe TargetedApi do

    let(:connection) do
      Mws::Connection.new(
        merchant: 'GSWCJ4UBA31UTJ',
        access: 'AYQAKIAJSCWMLYXAQ6K3', 
        secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
      )
    end

    let(:api) { Api.new(connection) }

    context '#add' do

      it 'should properly delegate to #submit' do
        expect(api.products).to receive(:submit).with([ 'resource_one', 'resource_two' ], :update, true).and_return('a_result')
        expect(api.products.add('resource_one', 'resource_two')).to eq('a_result')
      end

    end

    context '#update' do

      it 'should properly delegate to #submit' do
        expect(api.products).to receive(:submit).with([ 'resource_one', 'resource_two' ], :update).and_return('a_result')
        expect(api.products.update('resource_one', 'resource_two')).to eq('a_result')
      end

    end

    context '#patch' do

      it 'should properly delegate to #submit for products' do
        expect(api.products).to receive(:submit).with([ 'resource_one', 'resource_two' ], :partial_update).and_return('a_result')
        expect(api.products.patch('resource_one', 'resource_two')).to eq('a_result')
      end

      it 'should not be supported for feeds other than products' do
        expect { api.images.patch('resource_one', 'resource_two') }.to raise_error 'Operation Type not supported.'
      end

    end

    context '#delete' do

      it 'should properly delegate to #submit' do
        expect(api.products).to receive(:submit).with([ 'resource_one', 'resource_two' ], :delete).and_return('a_result')
        expect(api.products.delete('resource_one', 'resource_two')).to eq('a_result')
      end

    end

    context '#submit' do

      it 'should properly construct the feed and delegate to feeds' do
        resource = double :resource
        allow(resource).to receive(:to_xml)
        allow(resource).to receive(:sku).and_return('a_sku')
        allow(resource).to receive(:operation_type).and_return(:update)
        feed_xml = Nokogiri::XML::Builder.new do
          AmazonEnvelope('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:noNamespaceSchemaLocation' => 'amznenvelope.xsd') {
            Header {
              DocumentVersion '1.01'
              MerchantIdentifier 'GSWCJ4UBA31UTJ'
            }
            MessageType 'Product'
            PurgeAndReplace false
            Message {
              MessageID 1
              OperationType 'Update'
            }
          }
        end.doc.to_xml
        submission_info = double(:submission_info).as_null_object
        expect(api).to receive(:submit).with(feed_xml, feed_type: Feed::Type.PRODUCT, purge_and_replace: false).and_return(submission_info)
        tx = api.products.submit [ resource ], :update
        expect(tx.items.size).to eq(1)
        item = tx.items.first
        expect(item.id).to eq(1)
        expect(item.sku).to eq('a_sku')
        expect(item.operation).to eq(:update)
        expect(item.qualifier).to be nil
      end

    end

  end

end
