require 'translator'
require File.join(File.dirname(__FILE__), "lib", "fedena_hostel")
require File.join(File.dirname(__FILE__), "config", "breadcrumbs")
require 'dispatcher'

FedenaPlugin.register = {
  :name=>"fedena_hostel",
  :description=>"Fedena Hostel Module",
  :auth_file=>"config/hostel_auth.rb",
  :more_menu=>{:title=>"hostel_text",:controller=>"hostels",:action=>"hostel_dashboard",:target_id=>"more-parent"},
  :sub_menus=>[{:title=>"hostel_text",:controller=>"hostels",:action=>"index",:target_id=>"fedena_hostel"},
    {:title=>"rooms",:controller=>"room_details",:action=>"index",:target_id=>"fedena_hostel"},
    {:title=>"room_allocation",:controller=>"room_allocate",:action=>"index",:target_id=>"fedena_hostel"},
    {:title=>"fee_collection_text",:controller=>"hostel_fee",:action=>"hostel_fee_collection",:target_id=>"fedena_hostel"},
    {:title=>"hostel_fee_pay",:controller=>"hostel_fee",:action=>"hostel_fee_pay",:target_id=>"fedena_hostel"},
    {:title=>"hostel_fee_defaulters",:controller=>"hostel_fee",:action=>"hostel_fee_defaulters",:target_id=>"fedena_hostel"},
    {:title=>"pay_student_hostel_fee",:controller=>"hostel_fee",:action=>"index",:target_id=>"fedena_hostel"}],
  :dashboard_menu=>{:title=>"hostel_text",:controller=>"hostels",:action=>"hostel_dashboard",\
      :options=>{:class=>"option_buttons",:id => "hostel_button", :title => "manage_hostel"}},
  :student_profile_more_menu=>{:title=>"hostel_text",:destination=>{:controller=>"hostels",:action=>"student_hostel_details"}},
  :finance=>{:category_name=>"hostel",:destination=>{:controller=>"hostel_fee" , :action => "hostel_fees_report"},:plugin_name=>"fedena_hostel"},
  :css_overrides=>[{:controller=>"user",:action=>"dashboard"}],
  :autosuggest_menuitems=>[
    {:menu_type => 'link' ,:label => "autosuggest_menu.hostel",:value =>{:controller => :hostels,:action => :hostel_dashboard}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.hostel_details",:value =>{:controller => :hostels,:action => :index}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.add_hostel",:value =>{:controller => :hostels,:action => :new}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.room_details",:value =>{:controller => :room_details,:action => :index}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.add_room",:value =>{:controller => :room_details,:action => :new}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.add_room",:value =>{:controller => :room_details,:action => :new}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.room_allocation",:value =>{:controller => :room_allocate,:action => :index}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.hostel_fee_collection",:value =>{:controller => :hostel_fee,:action => :hostel_fee_collection}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.view_hostel_fee_collection",:value =>{:controller => :hostel_fee,:action => :hostel_fee_collection_view}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.hostel_fee_pay",:value =>{:controller => :hostel_fee,:action => :hostel_fee_pay}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.hostel_fee_defaulters",:value =>{:controller => :hostel_fee,:action => :hostel_fee_defaulters}},
    {:menu_type => 'link' ,:label => "autosuggest_menu.hostel_fee_search",:value =>{:controller => :hostel_fee,:action => :index}}

  ],
  :multischool_models=>%w{Hostel HostelFee HostelFeeCollection RoomAllocation RoomDetail Warden HostelRoomAdditionalField RoomAdditionalFieldOption HostelAdditionalFieldOption HostelRoomAdditionalDetail HostelFeeFinanceTransaction},
  :multischool_classes=>%w{DelayedHostelFeeCollectionJob}

}

Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

FedenaHostel.attach_overrides

if RAILS_ENV == 'development'
  ActiveSupport::Dependencies.load_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end
