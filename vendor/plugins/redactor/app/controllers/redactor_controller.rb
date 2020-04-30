class RedactorController < ApplicationController
      
  def upload
    redactor_upload = RedactorUpload.new
    redactor_upload.image = params[:file]

    if redactor_upload.save
      file_url =
        if Fedena.hostname.present? && !FedenaSetting.s3_enabled?
          URI.join(Fedena.hostname, URI.encode(redactor_upload.image.url)).to_s
        else
          redactor_upload.image.url
        end
      render :json => {:filelink=>file_url,:id=>redactor_upload.id}.to_json
    else
      render :json => {:error => "failed to upload",:error_message => redactor_upload.errors.full_messages }.to_json
    end
  end

  def post_upload
    s3_object_key = params[:key]
    policy = RedactorS3Helper.new
    policy.make_s3_connection
    s3_object = policy.fetch_s3_object(s3_object_key)
    redactor_upload = RedactorUpload.new(
      :name => "#{s3_object.key.split('/').last}",
      :image_file_name => "#{s3_object.key.split('/').last}",
      :image_file_size => "#{s3_object.size}",
      :image_content_type => RedactorUpload.set_content_type(s3_object.key.split('/').last),
      :image_updated_at => Time.now
    )
    if(redactor_upload.save)
      s3_new_object_key = redactor_upload.image.path
      filelink = policy.rename(s3_object_key,s3_new_object_key)
      render :json => {:filelink => filelink,:id=>redactor_upload.id}.to_json
    else
      render :json => {:error => "failed to upload",:error_message => redactor_upload.errors.full_messages }.to_json
    end
  end

end
