#Copyright 2010 Foradian Technologies Private Limited
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.
class Book < ActiveRecord::Base
  acts_as_taggable
  belongs_to :book_movement
  has_many :book_reservations, :dependent => :destroy
  has_many :book_additional_details, :dependent => :destroy
  validates_presence_of :book_number, :title, :author
  validates_uniqueness_of :book_number
  validates_uniqueness_of :barcode,:allow_blank => true
  before_destroy :delete_dependency
  attr_accessor :book_query
  named_scope :borrowed, :conditions => { :status => "Borrowed" }
  named_scope :available, :conditions => ["status=? or status= ?","Available","Reserved"]
  named_scope :barcode_as, lambda{|barcode| {:conditions => ["barcode = ?","#{barcode}"]}}
  named_scope :booknumber_as, lambda{|booknumber| {:conditions => ["book_number LIKE ?","%#{booknumber}%"]}}
  named_scope :title_as, lambda{|title| {:conditions => ["title LIKE ?","%#{title}%"]}}
  named_scope :author_as, lambda{|author| {:conditions => ["author LIKE ?","%#{author}%"]}}

  cattr_reader :per_page
  attr_accessor :book_add_type

  @@per_page = 25

  def validate
    if self.tag_list.present?
      t = self.tag_list
      t.each do|tag|
        if (tag.length > 30)
          self.errors.add_to_base(:custom_tag_tool_long)
          return false
        end
      end
    end
    
    if self.book_add_type =="barcode"
      self.errors.add_to_base(:barcode_is_needed) unless self.barcode.present?
      return false
    end
  end
  
#  def self.get_manage_book_csv_data(books)
#    csv_string=FasterCSV.generate do |csv|
#      cols = []
#      cols <<  "#{t('book_number')}"
#      cols <<  "#{t('title')}"
#      cols <<  "#{t('author')}"
#      cols <<  "#{t('tags_text')}"
#      cols <<  "#{t('status')}"
#      book_ids = books.collect(&:id)
#      fields = BookAdditionalField.find(:all,:select=> "DISTINCT book_additional_fields.name as field_name, book_additional_fields.id as field_id, book_additional_details.book_id as book_id, book_additional_details.additional_info as additional_info",:joins=>"INNER JOIN book_additional_details ON book_additional_details.book_additional_field_id = book_additional_fields.id",:conditions=>["book_additional_details.book_id IN (?)",book_ids]).group_by(&:book_id)   
#      field_hsh=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
#      fields.each do |key,val|
#        val.each do |field|
#          field_hsh[key][field.field_id] = field.additional_info
#        end
#      end  
#      additional_fields = BookAdditionalField.find(:all,:select=> "DISTINCT book_additional_fields.*",:joins=>"INNER JOIN book_additional_details ON book_additional_details.book_additional_field_id = book_additional_fields.id")
#      additional_fields.each do |additional_field|      
#        cols << additional_field.name
#      end
#      csv << cols
#      books.each do |book|
#        cols = []
#        cols << book.book_number
#        cols << book.title
#        cols << book.author
#        cols << book.tag_list
#        cols << t("#{book.status.downcase}")
#        additional_fields.each do |additional_field|
#          cols << (field_hsh[book.id.to_s][additional_field.id.to_s].present? ? field_hsh[book.id.to_s][additional_field.id.to_s] : '-')
#        end
#        csv << cols
#      end
#    end
#    return csv_string
#  end
  
#  def self.get_manage_book_csv_data(books)
#    csv_string=FasterCSV.generate do |csv|
#      cols = []
#      cols <<  "#{t('book_number')}"
#      cols <<  "#{t('title')}"
#      cols <<  "#{t('author')}"
#      cols <<  "#{t('tags_text')}"
#      cols <<  "#{t('status')}"
#      additional_fields = BookAdditionalField.find(:all,:select=> "DISTINCT book_additional_fields.*",:joins=>"INNER JOIN book_additional_details ON book_additional_details.book_additional_field_id = book_additional_fields.id")
#      additional_fields.each do |additional_field|      
#        cols << additional_field.name
#      end
#      csv << cols
#      books.each do |book|
#        cols = []
#        cols << book.book_number
#        cols << book.title
#        cols << book.author
#        cols << book.tag_list
#        cols << t("#{book.status.downcase}")
#        additional_fields.each do |additional_field|
#          additional_details = BookAdditionalDetail.find_by_book_id_and_book_additional_field_id(book.id,additional_field.id)
#          cols << (additional_details.present? ? additional_details.additional_info : '-')
#        end
#        csv << cols
#      end
#    end
#    return csv_string
#  end

  def get_student_id
    return Student.first(:conditions => ["admission_no LIKE BINARY(?)",self.book_movement.user.username]).id
  end

  def get_employee_id
    return  Employee.first(:conditions => ["employee_number LIKE BINARY(?)",self.book_movement.user.username]).id
  end

  def delete_dependency
    movements = BookMovement.find_all_by_book_id(self.id)
    BookMovement.destroy_all(:id => movements.map(&:id))
  end
  
  def self.manage_books(parameters)
#    if parameters[:sort].present?
#      sort = parameters[:sort_on]
#      books = Book.search(:status_like=>"#{sort}").all(:joins=>[""],:order => "soundex(book_number),length(book_number),book_number ASC",:include=>:tags)
#    else
#      books = Book.all(:order => "soundex(book_number),length(book_number),book_number ASC",:include=>:tags)
#    end 
     if parameters[:index] == "false"
      if parameters[:books].present?
        books = parameters[:books]   
        books = Book.find(books,:order=>"soundex(book_number),length(book_number),book_number ASC")
        
      end
     else
       books = Book.all(:order => "soundex(book_number),length(book_number),book_number ASC",:include=>:tags)
     end  
    data=[]
    col_heads=[]
      col_heads <<  "#{t('book_number')}"
      col_heads <<  "#{t('title')}"
      col_heads <<  "#{t('author')}"
      col_heads <<  "#{t('tags_text')}"
      col_heads <<  "#{t('status')}"
      
      book_ids = books.collect(&:id)
      fields = BookAdditionalField.find(:all,:select=> "DISTINCT book_additional_fields.name as field_name, book_additional_fields.id as field_id, book_additional_details.book_id as book_id, book_additional_details.additional_info as additional_info",:joins=>"INNER JOIN book_additional_details ON book_additional_details.book_additional_field_id = book_additional_fields.id",:conditions=>["book_additional_details.book_id IN (?)",book_ids]).group_by(&:book_id)   
      field_hsh=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      fields.each do |key,val|
        val.each do |field|
          field_hsh[key][field.field_id] = field.additional_info
        end
      end  
      additional_fields = BookAdditionalField.find(:all,:select=> "DISTINCT book_additional_fields.*",:joins=>"INNER JOIN book_additional_details ON book_additional_details.book_additional_field_id = book_additional_fields.id")
      additional_fields.each do |additional_field|      
        col_heads << additional_field.name
      end
    data << col_heads
    books.each do |book|
        cols = []
        cols << book.book_number
        cols << book.title
        cols << book.author
        cols << book.tag_list
        cols << t("#{book.status.downcase}")
        additional_fields.each do |additional_field|
          cols << (field_hsh[book.id.to_s][additional_field.id.to_s].present? ? field_hsh[book.id.to_s][additional_field.id.to_s] : '-')
        end
        data << cols
      end
    return data
  end
  
  def self.search_book(search_by,search_text)
    
    case search_by
    when "barcode"     
      self.barcode_as(search_text)
    when "Book Number"      
        self.booknumber_as(search_text)      
    when "title"
      self.title_as(search_text)     
    when "author"
      self.author_as(search_text)         
    when "tag"
      self.find_tagged_with(search_text,:order =>"soundex(book_number),length(book_number),book_number ASC")   
    end     
  end  

end
