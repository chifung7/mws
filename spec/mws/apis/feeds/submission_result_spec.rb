require 'spec_helper'
require 'nokogiri'

module Mws::Apis::Feeds

  class SubmissionResult
    attr_reader :responses
  end

  describe SubmissionResult do 
    let(:success_node) do
      Nokogiri::XML::Builder.new do
        Message {
          MessageID 1
          ProcessingReport {
            DocumentTransactionID 5868304010
            Summary {
              StatusCode 'Complete'
              ProcessingSummary {
                MessagesProcessed 1
                MessagesSuccessful 1
                MessagesWithError 0
                MessagesWithWarning 0
              }
            }
          }
        }
      end.doc.root
    end
    let(:error_node) do
      Nokogiri::XML::Builder.new do
        Message {
          MessageID 1
          ProcessingReport {
            DocumentTransactionID 5868304010
            Summary {
              StatusCode 'Complete'
              ProcessingSummary {
                MessagesProcessed 2
                MessagesSuccessful 0
                MessagesWithError 2
                MessagesWithWarning 1
              }
            }
            Result {
              MessageID 1
              ResultCode 'Error'
              ResultMessageCode 8560
              ResultDescription 'Result description 1'
              AdditionalInfo {
                SKU '3455449'
              }
            }
            Result {
              MessageID 2
              ResultCode 'Error'
              ResultMessageCode 5000
              ResultDescription "Result description 2"
              AdditionalInfo {
                SKU '8744969'
              }
            }
            Result {
              MessageID 3
              ResultCode 'Warning'
              ResultMessageCode 5001
              ResultDescription "Result description 3"
              AdditionalInfo {
                SKU '7844970'
              }
            }
          }
        }
      end.doc.root
    end

    it 'should not allow instance creation via new' do
      expect { SubmissionResult.new }.to raise_error NoMethodError
    end

    describe '.from_xml' do

      it 'should be able to be constructed from valid success xml' do
        result = SubmissionResult.from_xml success_node
        expect(result.transaction_id).to eq('5868304010')
        expect(result.status).to eq(SubmissionResult::Status.COMPLETE.sym)
        expect(result.messages_processed).to eq(1)
        expect(result.count_for(:success)).to eq(1)
        expect(result.count_for(:error)).to eq(0)
        expect(result.count_for(:warning)).to eq(0)
        expect(result.responses).to be_empty
      end

      it 'should be able to be constructed from valid error xml' do 
        result = SubmissionResult.from_xml error_node
        expect(result.transaction_id).to eq('5868304010')
        expect(result.status).to eq(SubmissionResult::Status.COMPLETE.sym)
        expect(result.messages_processed).to eq(2)
        expect(result.count_for(:success)).to eq(0)
        expect(result.count_for(:error)).to eq(2)
        expect(result.count_for(:warning)).to eq(1)
        expect(result.responses.size).to eq(3)

        response = result.response_for 1
        expect(response.type).to eq(SubmissionResult::Response::Type.ERROR.sym)
        expect(response.code).to eq(8560)
        response.description == 'Result description 1'
        expect(response.additional_info).to eq({
          sku: '3455449'
        })


        response = result.response_for 2
        expect(response.type).to eq(SubmissionResult::Response::Type.ERROR.sym)
        expect(response.code).to eq(5000)
        response.description == 'Result description 2'
        expect(response.additional_info).to eq({
          sku: '8744969'
        })

        response = result.response_for 3
        expect(response.type).to eq(SubmissionResult::Response::Type.WARNING.sym)
        expect(response.code).to eq(5001)
        response.description == 'Result description 3'
        expect(response.additional_info).to eq({
          sku: '7844970'
        })
      end

    end

    context '#==' do

      it 'should be reflexive' do
        a = SubmissionResult.from_xml success_node
        expect(a == a).to be true
      end

      it 'should be symmetric' do
        a = SubmissionResult.from_xml success_node
        b = SubmissionResult.from_xml success_node
        expect(a == b).to eq(b == a)
      end

      it 'should be transitive' do
        a = SubmissionResult.from_xml success_node
        b = SubmissionResult.from_xml success_node
        c = SubmissionResult.from_xml success_node
        expect(a == c).to eq(a == b && b == c)
      end

      it 'should handle comparison to nil' do
        a = SubmissionResult.from_xml success_node
        expect(a == nil).to be false
      end

    end

  end

end
