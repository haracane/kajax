require 'rubygems'
require 'net/https'

module GoogleDataAPI
  autoload :SpreadSheet, 'google_data_api/spread_sheet'
  
  def self.authenticate(options={})
    headers = (options[:headers] ||= {})
    headers['Content-Type'] ||= 'application/x-www-form-urlencoded'
    email = options[:email]
    password = options[:password]
    
    raise "google account email is nil" if email.nil?
    raise "google account password is nil" if password.nil?
    
    https = Net::HTTP.new('www.google.com', 443)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    path = '/accounts/ClientLogin'
    data = "accountType=HOSTED_OR_GOOGLE&Email=#{email}&Passwd=#{password}&service=wise"
    
    resp, data = https.post(path, data, headers)
    
    cl_string = data[/Auth=(.*)/, 1]

    STDERR.puts "[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}](INFO) google account '#{email}' authentication succeeded"
    
    headers["Authorization"] = "GoogleLogin auth=#{cl_string}"
  end
  
  module FeedReader
    def self.get_feed(uri, headers=nil, options={})
      uri = URI.parse(uri)
      https = Net::HTTP.new(uri.host, uri.port)
      if uri.port == 443 then
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      https.use_ssl ||= options[:use_ssl]
      https.verify_mode ||= options[:veriry_mode]
      return https.get(uri.path, headers)
    end
  end
end

