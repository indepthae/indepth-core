# Author: Hiroshi Ichikawa <http://gimite.net/>
# The license of this source is "New BSD Licence"

require "cgi"
require "stringio"

require "rubygems"
require "nokogiri"

require "google_drive/util"
require "google_drive/client_login_fetcher"
require "google_drive/oauth2_fetcher"
require "google_drive/error"
require "google_drive/authentication_error"
require "google_drive/spreadsheet"
require "google_drive/worksheet"
require "google_drive/collection"
require "google_drive/file"


module GoogleDrive

    # Use GoogleDrive.login or GoogleDrive.saved_session to get
    # GoogleDrive::Session object.
    class Session

        include(Util)
        extend(Util)

        UPLOAD_CHUNK_SIZE = 512 * 1024

        # The same as GoogleDrive.login.
        def self.login(mail, password, proxy = nil)
          session = Session.new(nil, ClientLoginFetcher.new({}, proxy))
          session.login(mail, password)
          return session
        end

        # The same as GoogleDrive.login_with_oauth.
        def self.login_with_oauth(oauth_token)
          case oauth_token
            when OAuth2::AccessToken
              fetcher = OAuth2Fetcher.new(oauth_token)
            else
              raise(GoogleDrive::Error,
                  "oauth_token is not OAuth2::Token: %p" % oauth_token)
          end
          return Session.new(nil, fetcher)
        end

        # The same as GoogleDrive.restore_session.
        def self.restore_session(auth_tokens, proxy = nil)
          return Session.new(auth_tokens, nil, proxy)
        end

        # Creates a dummy GoogleDrive::Session object for testing.
        def self.new_dummy()
          return Session.new(nil, Object.new())
        end

        # DEPRECATED: Use GoogleDrive.restore_session instead.
        def initialize(auth_tokens = nil, fetcher = nil, proxy = nil)
          if fetcher
            @fetcher = fetcher
          else
            @fetcher = ClientLoginFetcher.new(auth_tokens || {}, proxy)
          end
        end

        # Authenticates with given +mail+ and +password+, and updates current session object
        # if succeeds. Raises GoogleDrive::AuthenticationError if fails.
        # Google Apps account is supported.
        def login(mail, password)
          if !@fetcher.is_a?(ClientLoginFetcher)
            raise(GoogleDrive::Error,
                "Cannot call login for session created by login_with_oauth.")
          end
          begin
            @fetcher.auth_tokens = {
              :wise => authenticate(mail, password, :wise),
              :writely => authenticate(mail, password, :writely),
            }
          rescue GoogleDrive::Error => ex
            return true if @on_auth_fail && @on_auth_fail.call()
            raise(AuthenticationError, "Authentication failed for #{mail}: #{ex.message}")
          end
        end

        # Authentication tokens.
        def auth_tokens
          if !@fetcher.is_a?(ClientLoginFetcher)
            raise(GoogleDrive::Error,
                "Cannot call auth_tokens for session created by " +
                "login_with_oauth.")
          end
          return @fetcher.auth_tokens
        end

        # Authentication token.
        def auth_token(auth = :wise)
          return self.auth_tokens[auth]
        end

        # Proc or Method called when authentication has failed.
        # When this function returns +true+, it tries again.
        attr_accessor :on_auth_fail

        # Returns list of files for the user as array of GoogleDrive::File or its subclass.
        # You can specify query parameters described at
        # https://developers.google.com/google-apps/documents-list/#getting_a_list_of_documents_and_files
        #
        # files doesn't return collections unless "showfolders" => true is specified.
        #
        # e.g.
        #   session.files
        #   session.files("title" => "hoge", "title-exact" => "true")
        def files(params = {})
          url="https://www.googleapis.com/drive/v3/files?q=trashed%3Dfalse&fields=files%2Ckind"
          json_list = request(:get, url, :auth => :writely,:response_type => :json)
          json_files=json_list["files"]
          # json_files.delete_if {|json_file| {"application/vnd.google-apps.folder","application/vnd.google-apps.form"}.include? json_file["mimeType"] }
          #TODO , implement better logic !
          json_files.delete_if {|json_file| json_file["mimeType"]=="application/vnd.google-apps.folder" || json_file["mimeType"]=="application/vnd.google-apps.form" }
          files_list=json_files.map { |json_file| json_file_to_file(json_file) }
          return files_list
        end

        # Returns GoogleDrive::File or its subclass whose title exactly matches +title+.
        # Returns nil if not found. If multiple files with the +title+ are found, returns
        # one of them.
        def file_by_title(title)
          return files("title" => title, "title-exact" => "true")[0]
        end

        # Returns list of spreadsheets for the user as array of GoogleDrive::Spreadsheet.
        # You can specify query parameters described at
        # http://code.google.com/apis/spreadsheets/docs/2.0/reference.html#Parameters
        #
        # e.g.
        #   session.spreadsheets
        #   session.spreadsheets("title" => "hoge")
        def spreadsheets(params = {})
          query = encode_query(params)
          doc = request(
              :get, "https://spreadsheets.google.com/feeds/spreadsheets/private/full?#{query}")
          result = []
          doc.css("feed > entry").each() do |entry|
            title = entry.css("title").text
            url = entry.css(
              "link[rel='http://schemas.google.com/spreadsheets/2006#worksheetsfeed']")[0]["href"]
            result.push(Spreadsheet.new(self, url, title))
          end
          return result
        end

        # Returns GoogleDrive::Spreadsheet with given +key+.
        #
        # e.g.
        #   # http://spreadsheets.google.com/ccc?key=pz7XtlQC-PYx-jrVMJErTcg&hl=ja
        #   session.spreadsheet_by_key("pz7XtlQC-PYx-jrVMJErTcg")
        def spreadsheet_by_key(key)
          url = "https://spreadsheets.google.com/feeds/worksheets/#{key}/private/full"
          return Spreadsheet.new(self, url)
        end

        # Returns GoogleDrive::Spreadsheet with given +url+. You must specify either of:
        # - URL of the page you open to access the spreadsheet in your browser
        # - URL of worksheet-based feed of the spreadseet
        #
        # e.g.
        #   session.spreadsheet_by_url(
        #     "https://docs.google.com/spreadsheet/ccc?key=pz7XtlQC-PYx-jrVMJErTcg")
        #   session.spreadsheet_by_url(
        #     "https://spreadsheets.google.com/feeds/" +
        #     "worksheets/pz7XtlQC-PYx-jrVMJErTcg/private/full")
        def spreadsheet_by_url(url)
          # Tries to parse it as URL of human-readable spreadsheet.
          uri = URI.parse(url)
          if ["spreadsheets.google.com", "docs.google.com"].include?(uri.host) &&
              uri.path =~ /\/ccc$/
            if (uri.query || "").split(/&/).find(){ |s| s=~ /^key=(.*)$/ }
              return spreadsheet_by_key($1)
            end
          end
          # Assumes the URL is worksheets feed URL.
          return Spreadsheet.new(self, url)
        end

        # Returns GoogleDrive::Spreadsheet with given +title+.
        # Returns nil if not found. If multiple spreadsheets with the +title+ are found, returns
        # one of them.
        def spreadsheet_by_title(title)
          return spreadsheets({"title" => title})[0]
        end

        # Returns GoogleDrive::Worksheet with given +url+.
        # You must specify URL of cell-based feed of the worksheet.
        #
        # e.g.
        #   session.worksheet_by_url(
        #     "http://spreadsheets.google.com/feeds/" +
        #     "cells/pz7XtlQC-PYxNmbBVgyiNWg/od6/private/full")
        def worksheet_by_url(url)
          return Worksheet.new(self, nil, url)
        end

        # Returns the root collection.
        def root_collection
          return Collection.new(self, Collection::ROOT_URL)
        end

        # Returns the top-level collections (direct children of the root collection).
        def collections
          return self.root_collection.subcollections
        end

        # Returns a top-level collection whose title exactly matches +title+ as
        # GoogleDrive::Collection.
        # Returns nil if not found. If multiple collections with the +title+ are found, returns
        # one of them.
        def collection_by_title(title)
          return self.root_collection.subcollection_by_title(title)
        end

        # Returns GoogleDrive::Collection with given +url+.
        # You must specify either of:
        # - URL of the page you get when you go to https://docs.google.com/ with your browser and
        #   open a collection
        # - URL of collection (folder) feed
        #
        # e.g.
        #   session.collection_by_url(
        #     "https://drive.google.com/#folders/" +
        #     "0B9GfDpQ2pBVUODNmOGE0NjIzMWU3ZC00NmUyLTk5NzEtYaFkZjY1MjAyxjMc")
        #   session.collection_by_url(
        #     "http://docs.google.com/feeds/default/private/full/folder%3A" +
        #     "0B9GfDpQ2pBVUODNmOGE0NjIzMWU3ZC00NmUyLTk5NzEtYaFkZjY1MjAyxjMc")
        def collection_by_url(url)
          uri = URI.parse(url)
          if ["docs.google.com", "drive.google.com"].include?(uri.host) &&
              uri.fragment =~ /^folders\/(.+)$/
            # Looks like a URL of human-readable collection page. Converts to collection feed URL.
            url = "#{DOCS_BASE_URL}/folder%3A#{$1}"
          end
          return Collection.new(self, url)
        end

        # Creates new spreadsheet and returns the new GoogleDrive::Spreadsheet.
        #
        # e.g.
        #   session.create_spreadsheet("My new sheet")
        def create_spreadsheet(
            title = "Untitled",
            feed_url = "https://docs.google.com/feeds/documents/private/full")

          xml = <<-"EOS"
            <atom:entry
                xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns:docs="http://schemas.google.com/docs/2007">
              <atom:category
                  scheme="http://schemas.google.com/g/2005#kind"
                  term="http://schemas.google.com/docs/2007#spreadsheet"
                  label="spreadsheet"/>
              <atom:title>#{h(title)}</atom:title>
            </atom:entry>
          EOS

          doc = request(:post, feed_url, :data => xml, :auth => :writely)
          ss_url = doc.css(
            "link[rel='http://schemas.google.com/spreadsheets/2006#worksheetsfeed']")[0]["href"]
          return Spreadsheet.new(self, ss_url, title)

        end

        # Uploads a file with the given +title+ and +content+.
        # Returns a GoogleSpreadsheet::File object.
        #
        # e.g.
        #   # Uploads and converts to a Google Docs document:
        #   session.upload_from_string(
        #       "Hello world.", "Hello", :content_type => "text/plain")
        #
        #   # Uploads without conversion:
        #   session.upload_from_string(
        #       "Hello world.", "Hello", :content_type => "text/plain", :convert => false)
        def upload_from_string(content, title = "Untitled", params = {})
          return upload_from_io(StringIO.new(content), title, params)
        end

        # Uploads a local file.
        # Returns a GoogleSpreadsheet::File object.
        #
        # e.g.
        #   # Uploads and converts to a Google Docs document:
        #   session.upload_from_file("/path/to/hoge.txt")
        #
        #   # Uploads without conversion:
        #   session.upload_from_file("/path/to/hoge.txt", "Hoge", :convert => false)
        #
        #   # Uploads with explicit content type:
        #   session.upload_from_file("/path/to/hoge", "Hoge", :content_type => "text/plain")
        def upload_from_file(path, title = nil, params = {})
          file_name = ::File.basename(path)
          params = {:file_name => file_name}.merge(params)
          open(path, "rb") do |f|
            return upload_from_io(f, title || file_name, params)
          end
        end

        # Uploads a file. Reads content from +io+.
        # Returns a GoogleSpreadsheet::File object.
        def upload_from_io(io, title = "Untitled", params = {})
          upload_url="https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable"
          return upload_raw(:post, upload_url, io, title, params)
        end

        def upload_raw(method, url, io, title = "Untitled", params = {}) #:nodoc:

          # params = {:convert => true}.merge(params)
          pos = io.pos
          io.seek(0, IO::SEEK_END)
          total_bytes = io.pos - pos
          io.pos = pos
          content_type = nil  #params[:content_type]
          p params
          if !content_type && params[:file_name]
            p "Trying to match extension !!!=============================="
            content_type = EXT_TO_CONTENT_TYPE[::File.extname(params[:file_name]).downcase]
          end
          if !content_type
            content_type = "application/octet-stream"
          end
          initial_json={:name=>params[:file_name]}.to_json

          default_initial_header = {
              "Content-Type" => "application/json",
              "X-Upload-Content-Type" => content_type,
              "X-Upload-Content-Length" => total_bytes.to_s(),
          }
          #initial_full_url = concat_url(url, params[:convert] ? "?convert=true" : "?convert=false")
          initial_full_url = concat_url(url,"?convert=false")
          default_upload_header = {
                "Content-Type" => "application/json"
            }
          initial_response = request(method, initial_full_url,
              # :header => default_initial_header.merge(params[:header] || {}),
              :header => default_upload_header,
              :data => initial_json,
              :auth => :writely,
              :response_type => :response
          )
          upload_url = initial_response["location"]
          sent_bytes = 0
          while data = io.read(UPLOAD_CHUNK_SIZE)
            content_range = "bytes %d-%d/%d" % [
                sent_bytes,
                sent_bytes + data.bytesize - 1,
                total_bytes,
            ]
            upload_header = {
                "Content-Type" => content_type,
                "Content-Range" => content_range,
            }
            doc = request(
                :post, upload_url, :header => upload_header, :data => data, :auth => :writely)
            sent_bytes += data.bytesize
          end
          # return json_file_to_file(doc)
          return true
          # return entry_element_to_file(doc)

        end
        # def entry_element_to_file(entry) #:nodoc:
        #   kind=entry.css("kind").text.sub("drive#","")
        #   title = entry.css("title").text
        #   case type
        #     when "folder"
        #       return Collection.new(self, entry)
        #     when "spreadsheet"
        #       worksheets_feed_link = entry.css(
        #         "link[rel='http://schemas.google.com/spreadsheets/2006#worksheetsfeed']")[0]
        #       return Spreadsheet.new(self, worksheets_feed_link["href"], title)
        #     else
        #       return GoogleDrive::File.new(self, entry)
        #   end
        # end
        def json_file_to_file(json_entry)
          kind=json_entry["kind"].sub("drive#","")
          title=json_entry["title"]
          case kind
            when "file"
              return GoogleDrive::File.new(self, json_entry)
            when "fileList"
              return []
            when "folder"
              return []
            else
              return []
            end
        end
        def request(method, url, params = {}) #:nodoc:
          # Always uses HTTPS.
          url = url.gsub(%r{^http://}, "https://")
          data = params[:data]
          auth = params[:auth] || :wise
          if params[:header]
            extra_header = params[:header]
          elsif data
            extra_header = {"Content-Type" => "application/json"}
          else
            extra_header = {}
          end
          response_type = params[:response_type] || :xml

          while true
            response = @fetcher.request_raw(method, url, data, extra_header, auth)
            if response.code == "401" && @on_auth_fail && @on_auth_fail.call()
              next
            end
            if !(response.code =~ /^[23]/)
              raise(
                response.code == "401" ? AuthenticationError : GoogleDrive::Error,
                "Response code #{response.code} for #{method} #{url}: " +
                CGI.unescapeHTML(response.body))
            end
            if response.code.to_i ==204
              return true
            else
              return convert_response(response, response_type)
            end
          end

        end

        def inspect
          return "#<%p:0x%x>" % [self.class, self.object_id]
        end

      private

        def convert_response(response, response_type)
          case response_type
            when :xml
              unless response.body.nil?
                json=JSON.parse(response.body) unless  response.body.empty?
                xml=response.body
              end
              return Nokogiri.XML(xml)
            when :json
              return JSON.parse(response.body)
            when :raw
              return response.body
            when :response
              return response
            else
              raise(GoogleDrive::Error,
                  "Unknown params[:response_type]: %s" % response_type)
          end
        end

        def authenticate(mail, password, auth)
          params = {
            "accountType" => "HOSTED_OR_GOOGLE",
            "Email" => mail,
            "Passwd" => password,
            "service" => auth.to_s(),
            "source" => "Gimite-RubyGoogleDrive-1.00",
          }
          header = {"Content-Type" => "application/x-www-form-urlencoded"}
          response = request(:post,
            "https://www.google.com/accounts/ClientLogin",
            :data => encode_query(params),
            :auth => :none,
            :header => header,
            :response_type => :raw)
          return response.slice(/^Auth=(.*)$/, 1)
        end

    end

end
