module JWT
    class UrlSigner

        CONFIG_PATH = File.join(Rails.root, "config", "paperclip_signing_settings.yml")

        class << self
            
            attr_reader :secret_key
            attr_reader :expiry

            def configure
                @signing_enabled = false

                if File.exists? CONFIG_PATH
                    require 'jwt'
                    @signing_enabled = true
                    @key_hash = YAML.load_file(CONFIG_PATH)
                    @secret_key = @key_hash[:secret_key] || raise("Secret not specified")
                    @expiry = @key_hash[:expiry] || 4 * 3600
                end
                @key_hash
            end

            def signing_enabled?
                @signing_enabled
            end

        end

        def self.sign_url (url, expire = true)
            payload = {"url" => url}
            payload.merge!({:exp => Time.now.to_i + expiry.to_i}) if expire
            signature = make_signature(payload)
            return attach_signature(url,signature)             
        end

        def self.make_signature (payload)
            return encode_signature(JWT.encode(payload, secret_key, 'HS256'))
        end

        def self.verify_url (url)
            orig_url, signature = split_url_and_signature(url)            
            return signature ? verify_signature(orig_url,signature) : false
        end 
        
        def self.attach_signature (url, signature)
            separator = url =~ /\?/ ? '&' : '?'
            "#{url}#{separator}signature=#{signature}"
        end

        def self.split_url_and_signature (url)
            if url.match(/(.*)&signature=(.*)/)
                [$1,$2]
            end
        end

        def self.verify_signature (url, signature)
            data = JWT.decode(decode_signature(signature),secret_key, true, { 'algorithm' => 'HS256' })
            return data.first["url"] == url
        rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
            return false 
        end

        def self.encode_signature (signature)
            url_encode(Base64.encode64(signature))
        end

        def self.decode_signature (signature)
            Base64.decode64(url_decode(signature))
        end

        def self.url_encode(s)
            s.gsub('+','-').gsub('=','_').gsub('/','~').gsub(/\n/,'')
        end

        def self.url_decode(s)
            s.gsub('-','+').gsub('_','=').gsub('~','/')
        end
        
    end
end