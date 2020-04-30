class S3Asset
  class << self
    #compress assets to gzip format and copied into s3_assets directory
    def make_new_assets
      #      file_etag=load_etag_file #etag of all uncompressed files
      asset_files.each do |file|
        next if File.basename(file) == "Thumbs.db" 
        #        file_name=file.gsub("#{Rails.root}/public/","")
        #        new_file_path="#{Rails.root}/s3_assets/#{file_name}"
        #        if File.file? new_file_path
        #          unless file_etag[file_name]==Digest::MD5.hexdigest(File.read(file)) #check the orginal file modified or not
        #            File.delete(new_file_path)
        #            create_gzip_file(file)
        #            file_etag[file_name]=File.exist?(file) ? Digest::MD5.hexdigest(File.read(file)) : ''
        #          end
        #        else
        #          create_gzip_file(file)
        #          file_etag[file_name]=File.exist?(file) ? Digest::MD5.hexdigest(File.read(file)) : ''
        #        end
        create_gzip_file(file)
      end
      #      File.open("#{Rails.root}/s3_assets/file_etag.yml",'wb'){|f| f.write(file_etag.to_yaml)}
    end

    private

    #compress the file to gzip format and copy the file to image location as in the public folder.
    def create_gzip_file(file)      
      unless (MIME::Types.type_for(file).first.try(:media_type)=="image" or MIME::Types.type_for(file).first.try(:raw_sub_type)=="x-shockwave-flash")
        file_name=file.gsub("#{Rails.root}/public/","")
        new_file_path="#{Rails.root}/s3_assets/#{file_name}"
        base_name=File.basename(file)
        dir_name=new_file_path.gsub(base_name,"")
        #no need to compress image files
        FileUtils.mkdir_p(dir_name) unless File.directory? dir_name
        system("gzip -c #{file} > #{new_file_path}")
      end
    end

    #load or create etag file inside s3_assets folder
#    def load_etag_file
#      file= begin
#        File.open("#{Rails.root}/s3_assets/file_etag.yml")
#      rescue
#        Dir.mkdir("#{Rails.root}/s3_assets")
#        File.open("#{Rails.root}/s3_assets/file_etag.yml",'wb'){|f| f.write({}.to_yaml)}
#        File.open("#{Rails.root}/s3_assets/file_etag.yml")
#      end
#      YAML.load_file(file.path)
#    end
    #fetch all valid assets files from public directory for compress
    def asset_files
      asset_files=[]
      Dir["#{Rails.root}/public/**/*"].each do |file|
        asset_files<< file if File.file?file
      end
      asset_files
    end
  end
end