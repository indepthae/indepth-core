namespace :fedena do

  desc "change redactor upload links to s3"
  task :local_to_s3  => :environment do
    require 'logger'
    start_time = Time.now
    log = Logger.new('log/local_to_s3_1.log')
    log.info('====================================================================')
    log.info("Starting at #{start_time}")
    log.info('====================================================================')
    cf = Config.cloudfront_public
    modules = {
      "ApplicationInstruction" => 0,
      "BlogPost" => 0,
      "News" => 0,
      "OnlineExamQuestion" => 0,
      "OnlineExamOption" => 0,
      "OnlineExamScoreDetail" => 0, 
      "Reminder" => 0
    }
    content_names = {
      "ApplicationInstruction"=>"description",
      "BlogPost"=>"body",
      "News"=>"content",
      "OnlineExamOption"=>"option",
      "OnlineExamQuestion"=>"question",
      "OnlineExamScoreDetail"=>"answer" , 
      "Reminder" =>"body",       
    }
    total_schools = 0
    update_done = 0
    School.find_in_batches(:batch_size => 1000, :conditions => {:is_deleted => false}) do |schools|
      total_schools += schools.length
      schools.each do |school|
        MultiSchool.current_school = school
        log.info("============School:#{school.id} - #{school.code}")
        modules.each_pair do |modul, modul_occurence|
          log.info("=======#{modul}=======")
          obj = modul.constantize rescue nil
          if obj != nil
            content_name = content_names[modul]
            modul_klass = modul.classify.constantize
            table_name = modul_klass.table_name
            modul_klass.find_in_batches(:batch_size => 1000) do |objs|              
              modules[modul] = modules[modul] + objs.length if objs.present?
              log.info("===(#{objs.length})======")
              objs.each do |n|
                updated_timestamp = nil
                flag = false
                content_id = n.id #n["id"]
                content = n.send(content_name)
                nok = Nokogiri::HTML(content)
                results = nok.xpath("//img")
                results.each do |result|
                  if(result.attributes.present? and result.attributes['src'].present?)
                    src = result.attributes['src'].value
                    log.info(src)
                    regex = /redactor_uploads\/([0-9\/]*)images\//  ## regex to find partitioned redactor id
                    regex.match(src)                    
                    if($1.present? and !src.include? cf) # non cf urls
                      id = $1.to_i
                      rec = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id} and image_updated_at is NULL;")
                      if(rec.present?)
                        ## updates image_updated_at column if null
                        updated_timestamp = DateTime.parse(rec['updated_at']).strftime('%Y%m%d%H%m%S')
                        recup = ActiveRecord::Base.connection.update("update redactor_uploads SET image_updated_at = '#{rec['updated_at']}' where id = #{id}")
                        if recup == 1
                          log.info("successfully updated column image_updated_at in redactor_upload record")
                          log.info()      #blank line
                        end
                      end
                      src_without_ts = src.split('?').first
                      regex2 = /redactor_uploads\/([0-9\/]*)\/images\/(.*)/
                      regex2.match(src_without_ts)
                      got_id = $1
                      old_filename = $2
                      escaped_old_filename = old_filename.gsub('+','%2B')
                      rec_ = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id}")
                      if(rec_.present?)
                        true_filename = rec_['image_file_name'].gsub('+','%2B')
                        if true_filename != old_filename
                          recup = ActiveRecord::Base.connection.update("update redactor_uploads SET image_file_name = '#{old_filename}' where id = #{id}")
                          true_filename = escaped_old_filename
                        end
                        updated_timestamp = DateTime.parse(rec_["image_updated_at"]).strftime('%Y%m%d%H%m%S')
                        if src_without_ts.include?("images/#{old_filename}")
                          
                        end
                        if src_without_ts.include?("images/#{old_filename}")
                          src_without_ts = src_without_ts.gsub("/redactor_uploads/#{got_id}/images/#{old_filename}","/redactor_uploads/#{got_id}/images/#{updated_timestamp}/#{true_filename}")
                        elsif (src_without_ts.include?("images/#{true_filename}")) 
                          src_without_ts = src_without_ts.gsub("/redactor_uploads/#{got_id}/images/#{true_filename}","/redactor_uploads/#{got_id}/images/#{updated_timestamp}/#{true_filename}")
                        end
                      end
#                      unless(MultiSchool rescue nil) # checks and appends school_id if multischool & school_id is missing links
                        regex3 = /uploads\/([0-9\/]*)\/redactor_uploads/
                        regex3.match(src_without_ts)
                        log.info("going to check school id")
                        log.info($1)
                        if(!$1.present?)
                          log.info("missing school_id in link, hence appending it")
                          log.info()      #blank line
                          school_id = n.school_id
                          src_without_ts = src_without_ts.gsub("/uploads/redactor_uploads/","/uploads/#{school_id}/redactor_uploads/")
                        else # reverse school id partition 
                          school_id_found = $1.gsub('/','').to_i
                          src_without_ts = src_without_ts.gsub("/uploads/redactor_uploads/","/uploads/#{school_id_found}/redactor_uploads/")
                        end                       
                      new_src = "https://#{cf}#{src_without_ts}"
                      log.info("#{src} => #{new_src}")
                      log.info()      #blank line
                      log.info()      #blank line
                      content = content.gsub(src,new_src)
                      log.info(updated_timestamp)
                      flag = true
                    elsif($1.present? and src.include? cf)  # with cf urls
                      id = $1.to_i
                      new_cf_src = src.split('?').first
                      old_src = new_cf_src
                      log.info("before :: #{new_cf_src}")
                      rec = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id}")
                      if(rec.present?)
                        regex2 = /redactor_uploads\/([0-9\/]*)\/images\/(.*)/
                        regex3 = /uploads\/([0-9\/]*)\/redactor_uploads/
                        regex3.match(new_cf_src)
                        log.info("going to check school id")
                        log.info($1)
                        if(!$1.present?)
                          log.info("missing school_id in link, hence appending it")
                          log.info()      #blank line
                          school_id = n.school_id
                          new_cf_src = new_cf_src.gsub("/uploads/redactor_uploads/","/uploads/#{school_id}/redactor_uploads/")
                        else # reverse school id partition 
                          school_id_found = $1.gsub('/','').to_i
                          new_cf_src = new_cf_src.gsub("/uploads/redactor_uploads/","/uploads/#{school_id_found}/redactor_uploads/")
                        end
                        regex2.match(new_cf_src)
                        got_id = $1
                        old_filename = $2
                        escaped_old_filename = old_filename.gsub('+','%2B')
                        true_filename = rec['image_file_name'].gsub('+','%2B')
                        updated_timestamp = DateTime.parse(rec["image_updated_at"]).strftime('%Y%m%d%H%m%S')                        
                        if !old_filename.include?("#{updated_timestamp}") && true_filename != old_filename
                          recup = ActiveRecord::Base.connection.update("update redactor_uploads SET image_file_name = '#{old_filename}' where id = #{id}")
                          true_filename = escaped_old_filename
                        end
                        if !true_filename.include?("#{updated_timestamp}") && (new_cf_src.include?("images/#{true_filename}"))
                          new_cf_src = new_cf_src.gsub("/redactor_uploads/#{got_id}/images/#{true_filename}","/redactor_uploads/#{got_id}/images/#{updated_timestamp}/#{true_filename}")
                        end
                        log.info(new_cf_src)                         
                        log.info("attempted to change from #{old_src} => #{new_cf_src}")
                        content = content.gsub(old_src,new_cf_src)
                        flag = true
                      end
                      
                    end
                  end
                end
                if(flag)                  
                  modul_recup = ActiveRecord::Base.connection.update("update #{table_name} SET `#{content_name}` = #{ActiveRecord::Base.connection.quote(content)} where id = #{content_id}")
                  if modul_recup == 1
                    log.info "successfully updated links in #{table_name} for record#id:#{content_id}"
                    log.info()
                  end
                end
              end
            end        
          end
        end
      end      
    end    
    end_time = Time.now
    log.info("========Finished at #{end_time}")
    log.info("========Time taken #{(end_time - start_time)} ms")
    log.info("Total schools : #{total_schools}")
    modules.each_pair do |m,n|
      log.info("=====#{m} : #{n}occurences found =====")
    end
  end
end