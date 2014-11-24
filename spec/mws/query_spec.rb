require 'spec_helper'

module Mws

  class Query
    attr_reader :params
  end

  describe Query do
    
    let(:defaults) do
      {
        access: 'Q6K3SCWMLYAKIAJXAAYQ', 
        merchant: 'J4UBGSWCA31UTJ', 
        markets: [ 'ATVPDKIKX0DER', 'KIKX0DERATVPD' ],
        last_updated_after: 4.hours.ago
      }
    end

    let(:query) {  Query.new defaults }

    it 'should default SignatureMethod to HmacSHA256' do
      expect(query.params['SignatureMethod']).to eq('HmacSHA256')
    end

    it 'should default SignatureVersion to 2' do
      expect(query.params['SignatureVersion']).to eq('2')
    end

    it 'should default Timestamp to now in iso8601 format' do
      time = expect(URI.decode(query.params['Timestamp'])).to eq(Time.now.iso8601)
    end

    it 'should accept overrides to SignatureMethod' do
      expect(Query.new(defaults.merge(signature_method: 'HmacSHA1')).params['SignatureMethod']).to eq('HmacSHA1')
    end

    it 'should accept overrides to SignatureVersion' do
      expect(Query.new(defaults.merge(signature_version: 3)).params['SignatureVersion']).to eq('3')
    end

    it 'should accept overrides to Timestamp' do
      time = 4.hours.ago
      query = Query.new(defaults.merge(timestamp: time))
      expect(URI.decode(query.params['Timestamp'])).to eq(time.iso8601)
    end

    it 'should translate access to AWSAccessKeyId' do
      access_key = 'Q6K3SCWMLYAKIAJXAAYQ'
      expect(Query.new(defaults.merge(access: access_key)).params['AWSAccessKeyId']).to eq(access_key)
    end

    it 'should translate merchant or seller to seller_id' do
      merchant = 'J4UBGSWCA31UTJ'
      queries = [ Query.new(defaults.merge(merchant: merchant)), Query.new(defaults.merge(seller: merchant)) ]
      queries.each do | query |
        expect(query.params['SellerId']).to eq(merchant)
      end
    end

    it 'should gracefully handle empty markets list' do
      expect(Query.new(defaults.merge(markets: [])).params['MarketplaceIdList.Id.1']).to be nil
    end

    it 'should translate single market to MarketplaceIdList.Id.1' do
      market = 'ATVPDKIKX0DER'
      expect(Query.new(defaults.merge(markets: [ market ])).params['MarketplaceIdList.Id.1']).to eq(market)
    end

    it 'should translate multiple markets to MarketplaceIdList.Id.*' do
      markets = [ 'ATVPDKIKX0DER', 'KIKX0DERATVPD' ]
      query = Query.new defaults.merge(markets: markets)
      markets.each_with_index do | market, index |
        expect(query.params["MarketplaceIdList.Id.#{index + 1}"]).to eq(market)
      end
    end

    it 'should allow for overriding the list representation strategy via list_pattern' do
      markets = [ 'ATVPDKIKX0DER', 'KIKX0DERATVPD' ]
      list_pattern = '%{key}[%<index>d]'
      query = Query.new defaults.merge(markets: markets, list_pattern: list_pattern)
      markets.each_with_index do | market, index |
        expect(query.params["MarketplaceId[#{index + 1}]"]).to eq(market)
      end
    end

    it 'should sort query parameters lexicographically' do
      query.params.inject('') do | prev, entry |
        expect(entry.first).to be > prev
        entry.first
      end
    end

    it 'should convert to a compliant query string' do
      query_string = query.to_s
      query_string.split('&').each do | entry |
        key, value = entry.split '='
        expect(query.params[key]).to eq(value)
      end
    end

  end

end