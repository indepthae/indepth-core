require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_gallery")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")

FedenaPlugin.register = {
  :name=>"fedena_gallery",
  :description=>"Fedena Photo Module",
  :auth_file=>"config/gallery_auth.rb",
  :more_menu=>{:title=>"photo_text",:controller=>"galleries",:action=>"index",:target_id=>"more-parent"},
  #  :sub_menus=>[
  #    {:title=>"add_new_photo",:controller=>"galleries",:action=>"photo_add"},
  #    ],
  :student_profile_more_menu=>{:title=>"photo_text",:destination=>{:controller=>"galleries",:action=>"index"}},
  :multischool_models=>%w{GalleryCategory GalleryPhoto GalleryTag GalleryCategoryPrivilege}
}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaGallery.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end
