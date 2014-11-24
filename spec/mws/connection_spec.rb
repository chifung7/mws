require 'spec_helper'
require 'nokogiri'

module Mws

  class Connection
    attr_reader :scheme, :host, :merchant, :access, :secret
    public :request, :response_for, :parse
  end

  describe Connection do

    let(:defaults) {
      {
        merchant: 'GSWCJ4UBA31UTJ',
        access: 'AYQAKIAJSCWMLYXAQ6K3', 
        secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
      }
    }

    let(:connection) {
      Mws.connect(defaults)
    }

    context '.new' do

      it 'should default scheme to https' do
        expect(connection.scheme).to eq('https')
      end

      it 'should accept a custom scheme' do
        expect(Connection.new(defaults.merge(scheme: 'http')).scheme).to eq('http')
      end

      it 'should default host to mws.amazonservices.com' do
        expect(connection.host).to eq('mws.amazonservices.com')
      end

      it 'should accept a custom host' do
        expect(Connection.new(defaults.merge(host: 'mws.amazonservices.uk')).host).to eq('mws.amazonservices.uk')
      end

      it 'should require a merchant identifier' do
        expect {
          Connection.new(
            access: defaults[:access],
            secret: defaults[:secret]
          )
        }.to raise_error Mws::Errors::ValidationError, 'A merchant identifier must be specified.'
      end

      it 'should accept a merchant identifier' do
        expect(connection.merchant).to eq('GSWCJ4UBA31UTJ')
      end

      it 'should require an access key' do
        expect { 
          Connection.new(
            merchant: defaults[:merchant], 
            secret: defaults[:secret]
          )
        }.to raise_error Mws::Errors::ValidationError, 'An access key must be specified.'
      end

      it 'should accept an access key' do
        expect(connection.access).to eq('AYQAKIAJSCWMLYXAQ6K3')
      end

      it 'should require a secret key' do
        expect { 
          Connection.new(
            merchant: defaults[:merchant],
            access: defaults[:access]
          )
        }.to raise_error Mws::Errors::ValidationError, 'A secret key must be specified.'
      end

      it 'should accept a secret key' do
        expect(connection.secret).to eq('Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX')
      end

    end

    context '#get' do

      it 'should appropriately delegate to #request' do
        expect(connection).to receive(:request).with(:get, '/foo', { market: 'ATVPDKIKX0DER' }, nil, { version: 1 })
        connection.get('/foo', { market: 'ATVPDKIKX0DER' }, { version: 1 })
      end

    end

    context '#post' do

      it 'should appropriately delegate to #request' do
        expect(connection).to receive(:request).with(:post, '/foo', { market: 'ATVPDKIKX0DER' }, 'test_body', { version: 1 })
        connection.post('/foo', { market: 'ATVPDKIKX0DER' }, 'test_body', { version: 1 })
      end

    end

    context '#request' do

      it 'should construct a query, signer and make the request' do
        expect(Query).to receive(:new).with(
          action: nil, 
          version: nil, 
          merchant: 'GSWCJ4UBA31UTJ', 
          access: 'AYQAKIAJSCWMLYXAQ6K3', 
          list_pattern: nil
        ).and_return('the_query')
        signer = double('signer')
        expect(Signer).to receive(:new).with(
          method: :get,
          host: 'mws.amazonservices.com',
          path: '/foo',
          secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
        ).and_return(signer)
        expect(signer).to receive(:sign).with('the_query').and_return('the_signed_query')
        expect(connection).to receive(:response_for).with(:get, '/foo', 'the_signed_query', nil).and_return('the_response')
        expect(connection).to receive(:parse).with('the_response', {})
        connection.request(:get, '/foo', {}, nil, {})
      end

      it 'should merge additional request parameters into the query' do
        connection = Connection.new(
          merchant: 'GSWCJ4UBA31UTJ',
          access: 'AYQAKIAJSCWMLYXAQ6K3',
          secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
        )
        expect(Query).to receive(:new).with(
          action: nil, 
          version: nil, 
          merchant: 'GSWCJ4UBA31UTJ', 
          access: 'AYQAKIAJSCWMLYXAQ6K3', 
          list_pattern: nil,
          foo: 'bar',
          baz: 'quk'
        ).and_return('the_query')
        signer = double('signer')
        expect(Signer).to receive(:new).with(
          method: :get,
          host: 'mws.amazonservices.com',
          path: '/foo',
          secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
        ).and_return(signer)
        expect(signer).to receive(:sign).with('the_query').and_return('the_signed_query')
        expect(connection).to receive(:response_for).with(:get, '/foo', 'the_signed_query', nil).and_return('the_response')
        expect(connection).to receive(:parse).with('the_response', {})
        connection.request(:get, '/foo', { foo: 'bar', baz: 'quk' }, nil, {})
      end

      it 'should accept overrides to action, version and list_pattern' do
        expect(Query).to receive(:new).with(
          action: 'SubmitFeed', 
          version: '2009-01-01', 
          merchant: 'GSWCJ4UBA31UTJ', 
          access: 'AYQAKIAJSCWMLYXAQ6K3', 
          list_pattern: 'a_list_pattern'
        ).and_return('the_query')
        signer = double('signer')
        expect(Signer).to receive(:new).with(
          method: :get,
          host: 'mws.amazonservices.com',
          path: '/foo',
          secret: 'Ubzq/NskSrW4m5ncq53kddzBej7O7IE5Yx9drGrX'
        ).and_return(signer)
        expect(signer).to receive(:sign).with('the_query').and_return('the_signed_query')
        expect(connection).to receive(:response_for).with(:get, '/foo', 'the_signed_query', nil).and_return('the_response')
        expect(connection).to receive(:parse).with('the_response', { action: 'SubmitFeed', version: '2009-01-01' })
        connection.request(:get, '/foo', {}, nil, { action: 'SubmitFeed', version: '2009-01-01', list_pattern: 'a_list_pattern' })
      end

    end

    context '#parse' do
      
      it 'should parse error messages correctly' do
        body = <<-XML
        <?xml version="1.0"?>
        <ErrorResponse xmlns="https://mws.amazonservices.com/Orders/2011-01-01">
          <Error>
            <Type>Sender</Type>
            <Code>InvalidParameterValue</Code>
            <Message>CreatedAfter or LastUpdatedAfter must be specified</Message>
          </Error>
          <RequestId>fb03503e-97e3-4ed1-88e9-d93f4d2111c1</RequestId>
        </ErrorResponse>
        XML
        expect { connection.parse(body, {}) }.to raise_error do | error | 
          expect(error).to be_a Errors::ServerError
          expect(error.type).to eq('Sender')
          expect(error.code).to eq('InvalidParameterValue')
          expect(error.message).to eq('CreatedAfter or LastUpdatedAfter must be specified')
          expect(error.details).to eq('None')
        end
      end

      it 'should parse result based on custom action' do
        body = <<-XML
        <?xml version="1.0"?>
        <ListOrdersResponse xmlns="https://mws.amazonservices.com/Orders/2011-01-01">
          <ListOrdersResult>
            <Orders/>
            <CreatedBefore>2012-11-19T20:54:33Z</CreatedBefore>
          </ListOrdersResult>
          <ResponseMetadata>
            <RequestId>931137cb-add7-4232-ac08-b701435c8447</RequestId>
          </ResponseMetadata>
        </ListOrdersResponse>
        XML
        result = expect(connection.parse(body, action: 'ListOrders').name).to eq('ListOrdersResult')
      end

      it 'shoudl parse result base on custom xpath' do
        body = <<-XML
        <?xml version="1.0"?>
        <ListOrdersResponse xmlns="https://mws.amazonservices.com/Orders/2011-01-01">
          <ListOrdersResult>
            <Orders/>
            <CreatedBefore>2012-11-19T20:54:33Z</CreatedBefore>
          </ListOrdersResult>
          <ResponseMetadata>
            <RequestId>931137cb-add7-4232-ac08-b701435c8447</RequestId>
          </ResponseMetadata>
        </ListOrdersResponse>
        XML
        result = expect(connection.parse(body, xpath: '/ListOrdersResponse/ListOrdersResult').name).to eq('ListOrdersResult')
      end

    end

    context '#response_for' do

      it 'should properly handle a secure get request' do
        response = double(:response)
        expect(response).to receive(:body).exactly(3).times.and_return('response_body')
        http = double(:http)
        expect(http).to receive(:request) do | req |
          expect(req).to be_a Net::HTTP::Get
          expect(req.method).to eq('GET')
          expect(req.path).to eq('/?foo=bar')
          expect(req['User-Agent']).to eq('MWS Connect/0.0.1 (Language=Ruby)')
          expect(req['Accept-Encoding']).to eq('text/xml')
          response
        end
        expect(Net::HTTP).to receive(:start).with('mws.amazonservices.com', 443, use_ssl: true).and_yield(http)
        expect(connection.response_for(:get, '/', 'foo=bar', nil)).to eq('response_body')
      end

      it 'should properly handle an insecure get request' do
        connection = Connection.new(defaults.merge(scheme: 'http'))
        response = double(:response)
        expect(response).to receive(:body).exactly(3).times.and_return('response_body')
        http = double(:http)
        expect(http).to receive(:request) do | req |
          expect(req).to be_a Net::HTTP::Get
          expect(req.method).to eq('GET')
          expect(req.path).to eq('/?foo=bar')
          expect(req['User-Agent']).to eq('MWS Connect/0.0.1 (Language=Ruby)')
          expect(req['Accept-Encoding']).to eq('text/xml')
          response
        end
        expect(Net::HTTP).to receive(:start).with('mws.amazonservices.com', 80, use_ssl: false).and_yield(http)
        expect(connection.response_for(:get, '/', 'foo=bar', nil)).to eq('response_body')
      end

      it 'should properly handle requests with transport level errors' do
        response = double(:response)
        expect(response).to receive(:body).and_return(nil)
        expect(response).to receive(:code).and_return(500)
        expect(response).to receive(:msg).and_return('Internal Server Error')
        http = double(:http)
        expect(http).to receive(:request) do | req |
          expect(req).to be_a Net::HTTP::Get
          expect(req.method).to eq('GET')
          expect(req.path).to eq('/?foo=bar')
          expect(req['User-Agent']).to eq('MWS Connect/0.0.1 (Language=Ruby)')
          expect(req['Accept-Encoding']).to eq('text/xml')
          response
        end
        expect(Net::HTTP).to receive(:start).with('mws.amazonservices.com', 443, use_ssl: true).and_yield(http)
        expect { connection.response_for(:get, '/', 'foo=bar', nil) }.to raise_error do | error |
          # puts error.inspect
          #<Mws::Errors::ServerError: Type: HTTP, Code: 500, Message: Internal Server Error, Details: None>
          expect(error).to be_a Errors::ServerError
          expect(error.type).to eq('HTTP')
          expect(error.code).to eq(500)
          expect(error.message).to eq('Internal Server Error')
          expect(error.details).to eq('None')
        end
      end

      it 'should properly handle a post without a body' do
        response = double(:response)
        expect(response).to receive(:body).exactly(3).times.and_return('response_body')
        http = double(:http)
        expect(http).to receive(:request) do | req |
          expect(req).to be_a Net::HTTP::Post
          expect(req.method).to eq('POST')
          expect(req.path).to eq('/?foo=bar')
          expect(req['User-Agent']).to eq('MWS Connect/0.0.1 (Language=Ruby)')
          expect(req['Accept-Encoding']).to eq('text/xml')
          response
        end
        expect(Net::HTTP).to receive(:start).with('mws.amazonservices.com', 443, use_ssl: true).and_yield(http)
        expect(connection.response_for(:post, '/', 'foo=bar', nil)).to eq('response_body')
      end

      it 'should properly handle a post with a body' do
        response = double(:response)
        expect(response).to receive(:body).exactly(3).times.and_return('response_body')
        http = double(:http)
        expect(http).to receive(:request) do | req |
          expect(req).to be_a Net::HTTP::Post
          expect(req.method).to eq('POST')
          expect(req.path).to eq('/?foo=bar')
          expect(req.content_type).to eq('text/xml')
          expect(req.body).to eq('request_body')
          req['Content-MD5'] = Digest::MD5.base64digest('request_body').strip
          expect(req['User-Agent']).to eq('MWS Connect/0.0.1 (Language=Ruby)')
          expect(req['Accept-Encoding']).to eq('text/xml')
          response
        end
        expect(Net::HTTP).to receive(:start).with('mws.amazonservices.com', 443, use_ssl: true).and_yield(http)
        expect(connection.response_for(:post, '/', 'foo=bar', 'request_body')).to eq('response_body')
      end

    end

  end

end
