require_relative 'lib/qb_integration'

if File.exists? File.join(File.expand_path(File.dirname(__FILE__)), '.env')
  # TODO check an ENV variable i.e. RACK_ENV
  begin
    require 'dotenv'
    Dotenv.load
  rescue => e
    puts e.message
    puts e.backtrace.join("\n")
  end
end

class QuickbooksEndpoint < EndpointBase::Sinatra::Base
  set :logging, true

  Honeybadger.configure do |config|
    config.api_key          = ENV['HONEYBADGER_KEY']
    config.environment_name = ENV['RACK_ENV']
  end

  set :show_exceptions, false

  error do
    result 500, lookup_error_message
  end

  post '/add_product' do
    code, summary = QBIntegration::Product.new(@payload, @config).import
    result code, summary
  end

  post '/update_product' do
    code, summary = QBIntegration::Product.new(@payload, @config).import
    result code, summary
  end

  post '/add_order' do
    begin
      code, summary = QBIntegration::Order.new(@payload, @config).create
      result code, summary
    rescue QBIntegration::AlreadyPersistedOrderException => e
      result 500, e.message
    end
  end

  post '/update_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).update
    result code, summary
  end

  post '/cancel_order' do
    code, summary = QBIntegration::Order.new(@payload, @config).cancel
    result code, summary
  end

  post '/add_return' do
    code, summary = QBIntegration::ReturnAuthorization.new(@payload, @config).create
    result code, summary
  end

  post '/update_return' do
    code, summary = QBIntegration::ReturnAuthorization.new(@payload, @config).update
    result code, summary
  end

  post '/get_inventory' do
    stock = QBIntegration::Stock.new(@payload, @config)

    if stock.name.present? && stock.item
      add_object :inventory, stock.inventory
      result 200
    elsif stock.items.present?
      stock.inventories.each { |item| add_object :inventory, item }
      add_parameter 'quickbooks_poll_stock_timestamp', stock.last_modified_date
      result 200
    else
      result 200
    end
  end

  get '/auth/callback' do
    puts @config
    test = params.keys.map do |key|
      "#{key}: #{params[key]}"
    end.push("oauth_secret: [check logs for original auth request response]")
      .join('<br>')

    puts test
    return test
  end

  get '/auth' do
    callback_url = ENV['CALLBACK_URL']
    rt = QBIntegration::Auth.new().get_request_token callback_url
    puts "secret: #{rt.secret}\ntoken: #{rt.token}"
    redirect rt.authorize_url(:oauth_callback => callback_url)
  end

  get '/auth/get_access_token' do
    token = params[:token]
    secret = params[:secret]
    oauth_verifier = params[:oauth_verifier]

    access_token = QBIntegration::Auth.new().get_access_from_request(token, secret, oauth_verifier)

    [
      "token: #{access_token.token}",
      "secret: #{access_token.secret}"
    ].join("<br>")
  end

  post '/test' do
    puts @config
  end

  post '/get-invoice' do
    puts  'quickbooks_endpoint'
    puts @config
    i = QBIntegration::Order.new(@payload, @config).create
    puts i
  end

  def lookup_error_message
    case env['sinatra.error'].class.to_s
    when "Quickbooks::AuthorizationFailure"
      "Authorization failure. Please check your Quickbooks credentials"
    when "Quickbooks::ServiceUnavailable"
      "Quickbooks API appears to be inaccessible HTTP 503 returned."
    else
      env['sinatra.error'].message
    end
  end
end
