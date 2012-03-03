require 'rubygems'
require 'xmlsimple'
require 'yaml'

module GoogleDataAPI
  module SpreadSheet
    def self.get_spreadsheet_key(options={})
      GoogleDataAPI.authenticate(options) if options[:headers]["Authorization"].nil?
      spreadsheets_uri = 'https://spreadsheets.google.com/feeds/spreadsheets/private/full'
      
      doc = XmlSimple.xml_in(GoogleDataAPI::FeedReader.get_feed(spreadsheets_uri, options[:headers]).body)
    #  doc= Hpricot(get_feed(spreadsheets_uri, headers).body)
    
      spreadsheet_title = options[:spreadsheet_title]
    
      spreadsheet_id = nil
      (doc["entry"]).each do |entry|
        title = entry["title"][0]["content"]
        next if spreadsheet_title != title
        spreadsheet_id = entry["id"][0]
        break
      end
      
      if spreadsheet_id =~ /[^\/]+$/ then
        spreadsheet_key = $&
        STDERR.puts "[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}](INFO) get spreadsheet key '#{spreadsheet_key}'"
        return spreadsheet_key
      end
      
      return nil
    end
    
    def self.get_worksheet_id(options={})
      return options[:worksheet_id] if options[:worksheet_id]
      GoogleDataAPI.authenticate(options) if options[:headers]["Authorization"].nil?
    
      doc= XmlSimple.xml_in(GoogleDataAPI::FeedReader.get_feed("https://spreadsheets.google.com/feeds/worksheets/#{self.get_spreadsheet_key(options)}/private/full", options[:headers]).body)
      
      worksheet_title = options[:worksheet_title]
      worksheet_id = nil
      (doc["entry"]).each do |entry|
        title = entry["title"][0]["content"]
        next if worksheet_title != title
        worksheet_id = entry["id"][0]
        break
      end
      
      STDERR.puts "[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}](INFO) get worksheet id '#{worksheet_id}'"

      return worksheet_id
    end
    
    def self.get_feed_uri(feed_type, options={})
      feed_uri_key = "#{feed_type}_uri".intern
      return options[feed_uri_key] if options[feed_uri_key]

      GoogleDataAPI.authenticate(options) if options[:headers]["Authorization"].nil?
      
      doc= XmlSimple.xml_in(GoogleDataAPI::FeedReader.get_feed(self.get_worksheet_id(options), options[:headers]).body)
      
      feed_uri = nil
      doc["link"].each do |link|
        rel = link["rel"]
        next if rel !~ /#{feed_type}$/
        feed_uri = link["href"]
      end
      
      STDERR.puts "[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}](INFO) get #{feed_type} uri '#{feed_uri}'"
    
      return feed_uri
    end
    
    def self.get_csv_records(options={})
      GoogleDataAPI.authenticate(options) if options[:headers].nil? || options[:headers]["Authorization"].nil?
      
      feed_type = :cellsfeed
      feed_uri = self.get_feed_uri(feed_type, options)
      STDERR.puts "[#{Time.now.strftime '%Y-%m-%d %H:%M:%S'}](INFO) get #{feed_type} data from '#{feed_uri}'"
      doc= XmlSimple.xml_in(GoogleDataAPI::FeedReader.get_feed(feed_uri, options[:headers]).body)
      
      records = []
      doc["entry"].each do |entry|
        cell = entry["cell"]
        row = cell[0]["row"].to_i - 1
        col = cell[0]["col"].to_i - 1
        content = entry["content"]["content"]
        records[row] ||= []
        records[row][col] = content
  #      STDERR.puts "[#{row}][#{col}]->#{content}"
      end
      
      return records
    end
  
  end
end
