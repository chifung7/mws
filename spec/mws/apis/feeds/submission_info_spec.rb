require 'spec_helper'
require 'nokogiri'

module Mws::Apis::Feeds

  describe SubmissionInfo do 

    let(:submitted_node) do
      Nokogiri::XML::Builder.new do
        FeedSubmissionInfo {
          FeedSubmissionId 5868304010
          FeedType '_POST_PRODUCT_DATA_'
          SubmittedDate '2012-10-16T21:19:08+00:00'
          FeedProcessingStatus '_SUBMITTED_'
        }
      end.doc.root
    end

    let(:in_progress_node) do
      Nokogiri::XML::Builder.new do
        FeedSubmissionInfo {
          FeedSubmissionId 5868304010
          FeedType '_POST_PRODUCT_DATA_'
          SubmittedDate '2012-10-16T21:19:08+00:00'
          FeedProcessingStatus '_IN_PROGRESS_'
          StartedProcessingDate '2012-10-16T21:21:35+00:00'
        }
      end.doc.root
    end

    let(:done_node) do
      Nokogiri::XML::Builder.new do
        FeedSubmissionInfo {
          FeedSubmissionId 5868304010
          FeedType '_POST_PRODUCT_DATA_'
          SubmittedDate '2012-10-16T21:19:08+00:00'
          FeedProcessingStatus '_DONE_'
          StartedProcessingDate '2012-10-16T21:21:35+00:00'
          CompletedProcessingDate '2012-10-16T21:23:40+00:00'
        }
      end.doc.root
    end

    it 'should not allow instance creation via new' do
      expect { SubmissionInfo.new }.to raise_error NoMethodError
    end

    context '.from_xml' do

      it 'should be able to create an info object in a submitted state' do
        info = SubmissionInfo.from_xml submitted_node
        expect(info.id).to eq("5868304010")
        expect(info.status).to eq(SubmissionInfo::Status.SUBMITTED.sym)
        expect(info.type).to eq(Feed::Type.PRODUCT.sym)
        expect(info.submitted).to eq(Time.parse('2012-10-16T21:19:08+00:00'))
        expect(info.started).to be_nil
        expect(info.completed).to be_nil
      end

      it 'should be able to create an info object in and in progress state' do
        info = SubmissionInfo.from_xml in_progress_node
        expect(info.id).to eq("5868304010")
        expect(info.status).to eq(SubmissionInfo::Status.IN_PROGRESS.sym)
        expect(info.type).to eq(Feed::Type.PRODUCT.sym)
        expect(info.submitted).to eq(Time.parse('2012-10-16T21:19:08+00:00'))
        expect(info.started).to eq(Time.parse('2012-10-16T21:21:35+00:00'))
        expect(info.completed).to be_nil
      end

      it 'should be able to create an info object in a done state' do
        info = SubmissionInfo.from_xml done_node
        expect(info.id).to eq("5868304010")
        expect(info.status).to eq(SubmissionInfo::Status.DONE.sym)
        expect(info.type).to eq(Feed::Type.PRODUCT.sym)
        expect(info.submitted).to eq(Time.parse('2012-10-16T21:19:08+00:00'))
        expect(info.started).to eq(Time.parse('2012-10-16T21:21:35+00:00'))
        expect(info.completed).to eq(Time.parse('2012-10-16T21:23:40+00:00'))
      end

    end

    context '#==' do

      it 'should be reflexive' do
        a = SubmissionInfo.from_xml submitted_node
        expect(a == a).to be true
      end

      it 'should be symmetric' do
        a = SubmissionInfo.from_xml submitted_node
        b = SubmissionInfo.from_xml submitted_node
        expect(a == b).to eq(b == a)
      end

      it 'should be transitive' do
        a = SubmissionInfo.from_xml submitted_node
        b = SubmissionInfo.from_xml submitted_node
        c = SubmissionInfo.from_xml submitted_node
        expect(a == c).to eq(a == b && b == c)
      end

      it 'should handle comparison to nil' do
        a = SubmissionInfo.from_xml submitted_node
        expect(a == nil).to be false
      end

    end

  end

end