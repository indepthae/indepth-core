
require 'openssl'
require 'base64'
require 'uri'

# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

require 'jwt_url_signer'

JWT::UrlSigner.configure

class PaperclipAttachment
  def self.call(env)
    begin
      paperclip_attachment = is_paperclip_attachment_request(env["PATH_INFO"])
      if paperclip_attachment
        paperclip_attachment_return(env)
      else
        [404, {"Content-Type" => "text/html"}, ["Not Found"]]
      end
    rescue Exception => e
      log = Logger.new("log/paperclip_request_error.log")
      log.debug("\n\n")
      log.debug("#{env["PATH_INFO"]}")
      log.debug("#{e}")
      return [500, {"Content-Type" => "text/html"}, ["Sorry. Something Went Wrong."]]
    end
  end

  class << self
    def is_paperclip_attachment_request(request_path)
      url_path_ar = request_path.split("/") if request_path
      if url_path_ar and (url_path_ar.length == 6) and (url_path_ar[1]=="uploads") and (url_path_ar[3].to_i.to_s==url_path_ar[3].to_s)
        return true
      end
      return false
    end

    def paperclip_attachment_return(env)
      request_path=env["PATH_INFO"]
      request_host=env["SERVER_NAME"] 
      url_path_ar = request_path.split("/")
      begin 
        if url_path_ar[2]=="school_details" or env['rack.session'][:user_id].present? or url_path_ar[2].include?("applicant") or url_path_ar[2].include?("redactor") or verify_signature(env)
          model = url_path_ar[2].classify.constantize
          attachment_name = url_path_ar[4].classify.underscore
          record = model.find(url_path_ar[3])
          file_attachment = record.send(attachment_name)
          file_open = File.open(file_attachment.path(:original))
          cache_expire = 60*60*24*365
          return [200, {"Content-Type" => file_attachment.content_type, "Etag" => "'#{record.updated_at.strftime('%Y%m%d%H%m%S')}'", "Cache-Control" => "private", "Connection" => "keep-alive", "Expires" => Time.at(Time.now.to_i + cache_expire).strftime("%a, %d %b %Y %H:%m:%S GMT")}, [file_open.read]]
        else
          return [401, {"Content-Type" => "text/html"}, ["Unauthorized Access."]]
        end
      rescue Exception => e
        log = Logger.new("log/paperclip_request_error.log")
        log.debug("\n\n")
        log.debug("#{request_path}")
        log.debug("#{e}")
        return [500, {"Content-Type" => "text/html"}, ["Sorry. Something Went Wrong."]]
      end
    end
    
    def verify_signature (env)
      url = make_url(env)
      if JWT::UrlSigner.signing_enabled? && url.match(/[\?&]signature=/)
        return JWT::UrlSigner.verify_url(url)
      else
        return false
      end
    end
    
    def make_url (env)
      scheme = env["rack.url_scheme"] || "http"
      http_host = env["HTTP_HOST"] || "lvh.me:3000"
      path_info = env["PATH_INFO"] 
      query_string = env["QUERY_STRING"]

      url = "#{scheme}://#{http_host}#{path_info}"
      url = "#{url}?#{query_string}" if query_string
      url
    end 
    
  end

    
end