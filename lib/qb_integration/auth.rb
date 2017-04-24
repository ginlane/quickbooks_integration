module QBIntegration
  class Auth
    attr_reader :token, :secret

    def initialize(credentials = {})
      @token  = credentials[:token]
      @secret = credentials[:secret]
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
    end

    def get_request_token(callback_url)
      @request_token ||= consumer.get_request_token(:oauth_callback => callback_url)
      puts "request_token: #{@request_token}"

      @request_token
    end

    def get_access_from_request(t, s, oauth_verifier)
      @request_token ||= OAuth::RequestToken.new(consumer, t, s)
      begin
        @request_token.get_access_token oauth_verifier: oauth_verifier
      rescue Exception => e

        puts e.request.body

        raise e
      end
    end

    private

    def consumer
      OAuth::Consumer.new(ENV['QB_CONSUMER_KEY'], ENV['QB_CONSUMER_SECRET'],
                          site:                'https://oauth.intuit.com',
                          request_token_path:  '/oauth/v1/get_request_token',
                          authorize_url:       'https://appcenter.intuit.com/Connect/Begin',
                          access_token_path:   '/oauth/v1/get_access_token')
    end
  end
end
