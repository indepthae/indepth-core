if (File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml'))
  module AWS
    module S3
      class S3Object
        class << self
          def copy(key, copy_key, bucket = nil, options = {})                        
            bucket          = bucket_name(bucket)
            key = URI.escape(key).gsub('+','%2B')
            source_key      = path!(bucket, key)
            default_options = {'x-amz-copy-source' => source_key}
            target_key      = path!(bucket, copy_key)
            returning put(target_key, default_options.merge(options)) do
              acl(copy_key, bucket, acl(key, bucket)) if options[:copy_acl]
            end
          end

        end
      end

      class Connection
        class << self
          def prepare_path(path)
            path = path.remove_extended unless path.valid_utf8?
            URI.escape(URI.unescape(path)).gsub('+','%2B').gsub('\n',"%0A").gsub('\r',"%0D")            
          end
        end

        def authenticate!(request)
          request['Host'] = @options[:server]
          request['Authorization'] = Authentication::Header.new(request, access_key_id, secret_access_key)
        end
      end

      class Authentication
        class CanonicalString < String #:nodoc:
          def initialize(request, options = {})
            super()
            @request = request
            @headers = {}
            @options = options
            # "For non-authenticated or anonymous requests. A NotImplemented error result code will be returned if
            # an authenticated (signed) request specifies a Host: header other than 's3.amazonaws.com'"
            # (from http://docs.amazonwebservices.com/AmazonS3/2006-03-01/VirtualHosting.html)
            request['Host'] ||= DEFAULT_HOST
            build
          end
        end
      end
      
    end
  end
end
