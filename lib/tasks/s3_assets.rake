require 's3_assets.rb'
namespace :fedena do
  desc "Prepare and upload the assets to S3"
  task :upload_assets  => :environment do
    start_time = Time.now
    if File.exists?('config/s3_assets_settings.yml')
      settings=YAML.load(open('config/s3_assets_settings.yml'))[RAILS_ENV]
      puts "\nValidating connection..."
      `s3cmd ls s3://#{settings['bucket']}/`
      raise Exception.new('Please install and setup s3cmd and continue...') unless $?.success?
      #load defaults to public
      ApplicationController.helpers.javascript_include_tag :defaults, :cache => 'cache/javascripts/all'
      puts "\n\nPreparing files"
      S3Asset.make_new_assets
      puts "\n\nUploading files to S3, this will take a few minutes...\n"
      system("s3cmd sync --exclude-from public/s3_assets_ignore --acl-public --no-mime-magic s3_assets/ -r --add-header 'Content-Encoding: gzip' s3://#{settings['bucket']}")
      system("s3cmd sync --exclude-from public/s3_images_ignore --acl-public --no-mime-magic public/images/ -r  s3://#{settings['bucket']}/images/")
    else
      raise Exception.new('Please configure s3_assets_settings and continue...') 
    end
    end_time = Time.now
    puts "start : #{start_time}"
    puts "end : #{end_time}"
  end
end