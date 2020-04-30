class FormSubmission < ActiveRecord::Base
  belongs_to		:form
  belongs_to    :user
  serialize :response
  if FedenaSetting.elasticsearch_enabled? and self.connection.table_exists? 'form_submissions'
    searchkick :index_name => "#{table_name}_#{Rails.configuration.database_configuration[RAILS_ENV]['database']}_#{RAILS_ENV}",
      :settings => {
      :analysis => {
        :analyzer => {
          :form_fields => {
            :type => "custom",
            :tokenizer => "standard",
            :filter => ['lowercase']
          }
        }
      }
    },
      :mappings => {
      "form_submissions" => {
        "properties" => {
          
        }
      },
      "_default_" => {
        "date_detection" => false
      }
    }
  end

  def self.build_and_send_elastic_query csv,filter_hash={}
    filter_arr = []
    if filter_hash.present?
      filters = extract_filters(filter_hash)
      filter_arr = filters if filters.present?
    end
    search_hash = {
      :bool=>{
        :must => filter_arr
      }
    }
    filter_arr << {:match => {'form_id' => @form_id}} if @form_id.present?
    filter_arr << {:match => {'school_id' => MultiSchool.current_school.id}} if(MultiSchool rescue nil)
    page = @pagination.present? ? @pagination[:page] : 0
    per_page = @pagination.present? ? @pagination[:per_page] : 12
    if(csv.present? and csv)      
      if searchkick_index.exists? # checks if index present with elasticsearch engine
        kicksearch :query=>search_hash, :load => false
      else
        reindex
        return Array.new #returns blank record for initial index creation case
      end
    else
      if searchkick_index.exists? # checks if index present with elasticsearch engine
        kicksearch :query=>search_hash, :load => false, :page=> page, :per_page=> per_page #unless(@csv.present? and @csv)
      else # if index is not present with elasticsearch engine
        reindex #will reindex hence making a blank index if no data exists.
        return Array.new #returns blank record for initial index creation case
      end
    end



    #    kicksearch :query=>@search_hash, :load => false if(@csv.present? and @csv)
    #    kicksearch :query=>@search_hash, :load => false, :page=> page, :per_page=> per_page unless(@csv.present? and @csv)
  end
  
  def search_data
    hsh = data_hash self
    hsh.merge!('school_id' => self.school_id) if MultiSchool rescue nil
    return hsh
  end

  def self.filter form_id,pagination,filter_hash={}
    @form_id = form_id
    @pagination = pagination
    filter_arr = []
    #    filter_arr << {:match => {'form_id' => form_id}}
    return build_and_send_elastic_query(false,filter_hash)
  end
  
  def verify_submission files
    form = self.form
    form_fields = form.form_template.form_fields
    settings = get_settings(form_fields)
    error_fields = []
    response = self.response
    response = JSON.parse(response)
    form_fields.each do |field|
      if settings["#{field.id}"] == 'true'
        if response["#{field.field_type}"].present?
          if field.field_type == 'file'
            error_fields << field.id unless files.present? and files["#{field.id}"].present? and files["#{field.id}"]['value'].present?
          elsif !(response["#{field.field_type}"]["#{field.id}"].present? and response["#{field.field_type}"]["#{field.id}"]['value'].present?)
            error_fields << field.id
          end
        else
          error_fields << field.id
        end
      end
    end
    if error_fields.present?
      form.fields_missing = error_fields.join(',')
      form.errors.add_to_base(t('forms.mandatory_fields_must'))
    end
    return form
  end

  def get_settings(fields)
    settings = {}
    fields.each do |field|
      if(field.field_settings.present?)
        setting = JSON.parse(field.field_settings)
        settings["#{field.id}"] = setting['mandatory'].present? ? setting['mandatory'] : false
      end
    end
    return settings
  end

  def self.get_response_hash form_id,pagination,csv,filter_hash={}
    if FedenaSetting.elasticsearch_enabled?
      @form_id = form_id
      @pagination = pagination
      #      filter_hash = {} if filter_hash == 'null'
      return build_and_send_elastic_query(csv,filter_hash)
    else
      page = pagination.present? ? pagination['page'] : nil
      per_page = pagination.present? ? pagination['per_page'] : 20
      arr = FormSubmission.find_all_by_form_id(form_id,:order=>"updated_at DESC") unless(csv.present? and csv)
      arr = FormSubmission.find_all_by_form_id(form_id,:order=>"updated_at DESC") if(csv.present? and csv)
      #      return (make_hash arr)
      return arr
    end
  end


  def self.get_user_response_hash form_id, user
    conditions = []
    if user.parent
      uid = user.guardian_entry.current_ward.user_id
      conditions = ['ward_id = ?',uid]
    end
    arr = user.form_submissions.find_all_by_form_id(form_id,:select=>"id,response,updated_at",:order=>"updated_at DESC",:conditions => conditions)
    return make_user_hash arr
  end

  def self.get_csv_data form_id,filter_hash={}
    form = Form.find(form_id)
    fields = form.form_template.form_fields.all(:conditions=>["field_type != ? and field_type != ?", 'hr','file'])
    csv = true
    csv_string = ""
    form_submissions = get_response_hash(form.id,{},csv,filter_hash)
    if form_submissions.present?
      csv_string=FasterCSV.generate do |csv|
        cols=["#{t('no_text')}"]+fields.map(&:label)
        csv << cols.flatten
        cnt = 1
        form_submissions.each do |form_submission|
          col=[]
          form_submission = form_submission.search_data unless FedenaSetting.elasticsearch_enabled?
          col << cnt
          cnt = cnt.next
          fields.each do |field|
            if field.field_type == 'file' ## skip file field data
            elsif field.field_type == 'checkbox'
              if FedenaSetting.elasticsearch_enabled?
                col << (form_submission[field.id].present? ? form_submission[field.id].join(' ') : '')
              else
                col << (form_submission["#{field.id}"].present? ? form_submission["#{field.id}"].join(' ') : '')
              end
            else
#              col << (FedenaSetting.elasticsearch_enabled? ? form_submission[field.id] : form_submission.search_data["#{field.id}"])
              col << (FedenaSetting.elasticsearch_enabled? ? form_submission[field.id] : form_submission["#{field.id}"])
            end
          
            #          end
          end
          csv << col.flatten
        end
      end
    end
    return csv_string
  end

  def self.get_analysed_hash form,fields,target=nil
    hash = {}
    condition = {}
    condition[:target] = target if target.present?
    submission_records = form.form_submissions.all(:conditions=>condition)
    submissions = submission_records.collect{
      |s|
      r = s.response
      r = JSON.parse(r) if r.is_a? String
      fields.each do |field|
        hash[field.id] = {} unless hash[field.id].present?
        if ['select','radio','checkbox'].include? field.field_type
          field_options = field.form_field_options
          if r[field.field_type]["#{field.id}"].present?
            
            if r[field.field_type]["#{field.id}"]['option_id'].present? and field.field_type != 'checkbox'
              field_options.each do |option|
                if(r[field.field_type]["#{field.id}"]['value'] == option.value)
                  unless hash[field.id][option.id].present?
                    hash[field.id][option.id] = {}
                    hash[field.id][option.id]['label'] = option.label
                    hash[field.id][option.id]['count'] = 1
                    hash[field.id][option.id]['weight'] = option.weight
                    hash[field.id]['count'] = 1
                  else
                    hash[field.id][option.id]['count'] = hash[field.id][option.id]['count'].next
                    hash[field.id]['count'] = hash[field.id]['count'].next
                  end
                end
              end
            elsif(r[field.field_type]["#{field.id}"].present? and field.field_type == 'checkbox')
              field_options.each do |option|
                if(r[field.field_type]["#{field.id}"]['value'].present? and r[field.field_type]["#{field.id}"]['value']["#{option.id}"] == option.value)
                  unless hash[field.id][option.id].present?
                    hash[field.id][option.id] = {}
                    hash[field.id][option.id]['label'] = option.label
                    hash[field.id][option.id]['count'] = 1
                    hash[field.id][option.id]['weight'] = option.weight
                    hash[field.id]['count'] = 1
                  else
                    hash[field.id][option.id]['count'] = hash[field.id][option.id]['count'].next
                    hash[field.id]['count'] = hash[field.id]['count'].next
                  end
                end
              end
            end
          end
        else
          unless field.field_type == 'hr'
            full_name = "#{s.user.full_name} #{s.user.username}"
            hash[field.id]["#{full_name}"] = r[field.field_type]["#{field.id}"]['value']
          end
        end
      end
    }
    return hash
  end

  def data_hash r
    hash = Hash.new()
    school_id = r.school_id
#    p r
#    p r.response.class
    r.response = JSON.parse(r.response) if r.response.is_a? String
    (r.response).collect {

      |k,v|
      h = Hash.new()
      if v.present?
        v.each do |a,b|
          key = a # id of field

          if k=='file'
            if b['value'].present?
              file = FormFileAttachment.find_one_without_school(b['value'])
              #            value = file.attachment.url if file.present?
              if file.present?
                value = []
                value << file.attachment_file_name
#                value << file.attachment.url
                value << file.attachment.url(:original,false)
              end
            end
          elsif k=='checkbox'
            temp = []
            if b['value'].present?
              b['value'].each do |x,y|
                temp << y
              end
            end
            value = temp
          else
            value = b["value"] # value selected or filled by user for a field
          end
          h[key] = value if value.present?
          hash.merge!(h)
        end
      end
    }
    #    hash.merge!('school_id' => r.school_id) if MultiSchool rescue nil
    hash['target_name'] = User.find_one_without_school(r.target,:select=>"first_name,last_name").full_name if r.target.present?
    hash['form_id'] = r.form_id
    hash['user_id'] = r.user_id
    hash['target_id'] = r.target
    r.school_id = school_id
    return hash
  end
  
  def self.make_user_hash arr
    hash = []
    i = 0
    arr.collect {
      |r|
      hash[i] = Hash.new()
      hash[i]['id'] = r.id
      hash[i]['updated_at'] = r.updated_at
      r.response = JSON.parse(r.response) if r.response.is_a? String
      (r.response).collect {
        |k,v|
        h = Hash.new()
        if v.present?
          v.each do |a,b|
            key = a # id of field
            value = b["value"] # value selected or filled by user for a field
            if k=='file'
              file = FormFileAttachment.find_by_id(value)
              #            value = file.attachment.url if file.present?
              #            value = file.attachment_file_name if file.present?
              if file.present?
                value = []
                value << file.attachment_file_name
#                value << file.attachment.url
                value << file.attachment.url(:original,false) if FedenaSetting.s3_enabled?
                value << file.attachment.url unless FedenaSetting.s3_enabled?
              end
            end
            h[key] = value
            hash[i]['response'] = Hash.new unless hash[i]['response'].present?
            hash[i]['response'][key] = value
            #        hash[i]['response'].merge!(h)
          end
        end
      }
      i = i.next
    }
    return hash
  end

  def self.extract_filters filter_hash
    filter_arr = []
    filter_hash.each do |k,v| if filter_hash.present?
        h = Hash.new
        case v['criteria']
        when '1'
          h[:match_phrase]  = { k => {'query' => v['criteria_text'] } } if v['criteria_text'].present?
        when '2'
          h[:match]  = { k => {'query' => v['criteria_text'],:operator => 'or' } } if v['criteria_text'].present?
        end
#        case v['criteria']
#        when '1' # exact match
#          h[:match]  = { k => v['criteria_text'] } if v['criteria_text'].present?
#        when '2' # starts with
#          h[:regexp] = { k => "#{v['criteria_text']}.*" } if v['criteria_text'].present?
#        when '3' # ends with
#          h[:regexp] = { k => ".*#{v['criteria_text']}" } if v['criteria_text'].present?
#        when '4' # anywhere
#          h[:regexp] = { k => ".*#{v['criteria_text']}.*" } if v['criteria_text'].present?
#        end
        filter_arr << h
      end
    end
    return filter_arr.delete_if {|key| key == {} }
  end

  def self.consolidated_hash form_id
    if FedenaSetting.elasticsearch_enabled?
      @form_id = form_id
      @pagination = pagination
      #      filter_hash = {} if filter_hash == 'null'
      return build_and_send_elastic_query(false)
    else
      page = pagination.present? ? pagination['page'] : 0
      per_page = pagination.present? ? pagination['per_page'] : 20
      arr = FormSubmission.find_all_by_form_id(form_id,:order=>"updated_at DESC").paginate(:page=>page,:per_page=>per_page)#.map(&:response)
      #      return (make_hash arr)
    end
  end

end
