require 'spec_helper'
require 'nokogiri'

module Mws::Apis::Feeds

  describe Transaction do 

    let(:submission_info) do
      SubmissionInfo.from_xml(
        Nokogiri::XML::Builder.new do
          FeedSubmissionInfo {
            FeedSubmissionId 5868304010
            FeedType '_POST_PRODUCT_DATA_'
            SubmittedDate '2012-10-16T21:19:08+00:00'
            FeedProcessingStatus '_SUBMITTED_'
          }
        end.doc.root
      )
    end
    
    describe '.new' do

      it 'should be able to create a transaction with no items' do
        transaction = Transaction.new submission_info
        expect(transaction.id).to eq("5868304010")
        expect(transaction.status).to eq(SubmissionInfo::Status.SUBMITTED.sym)
        expect(transaction.type).to eq(Feed::Type.PRODUCT.sym)
        expect(transaction.submitted).to eq(Time.parse('2012-10-16T21:19:08+00:00'))
        expect(transaction.items).to be_empty
      end

      it 'should be able to create a transaction with items' do
        transaction = Transaction.new submission_info do
          item 1, '12345678', :update
          item 2, '87654321', :update, :main
          item 3, '87654321', :delete, :other
        end

        expect(transaction.items.length).to eq(3)

        item = transaction.items[0]
        expect(item.id).to eq(1)
        expect(item.sku).to eq('12345678')
        expect(item.operation).to eq(:update)
        expect(item.qualifier).to be_nil

        item = transaction.items[1]
        expect(item.id).to eq(2)
        expect(item.sku).to eq('87654321')
        expect(item.operation).to eq(:update)
        expect(item.qualifier).to eq(:main)

        item = transaction.items[2]
        expect(item.id).to eq(3)
        expect(item.sku).to eq('87654321')
        expect(item.operation).to eq(:delete)
        expect(item.qualifier).to eq(:other)
      end

    end

  end

end