if (Multischool rescue nil)
  cf = "d1mybxcsjwocv2.cloudfront.net"
  schools = School.all
  schools.each do |school|
    MultiSchool.current_school = school
    modules = ["News","BlogPost","OnlineExamQuestion","OnlineExamOption"]
    modules.each do |modul|
      obj = modul.constantize rescue nil
      if obj != nil
        objs = obj.all
        objs.each do |n|
          case modul
          when "News"
            content = n.content
          when "BlogPost"
            content = n.body
          when "OnlineExamOption"
            content = n.option
          when "OnlineExamQuestion"
            content = n.question
          end
          nok = Nokogiri::HTML(content)
          results = nok.xpath("//img")
          results.each do |result|
            if(result.attributes.present? and result.attributes['src'].present?)
              srcs = result.attributes['src'].value
              regex = /redactor_uploads\/([0-9\/]*)images\//
              srcs.each do |src|
                regex.match(src)
                if($1.present?)
                  id = $1.split('/').join.to_i
                  p src
                  p id
                  rec = ActiveRecord::Base.connection.select_one("select * from redactor_uploads where id = #{id};")
                  if rec.present?
                    if rec['school_id'].blank?
                      ## updates school id in redactor uploads table
                      recup = ActiveRecord::Base.connection.update("update redactor_uploads SET school_id = #{school.id} where id = #{id}")
                      if recup == 1
                        p "successfully updated redactor_upload record"
                      end
                    else
                      p 'school id present in redactor upload record'
                    end
                    if(!src.include? cf)
                      ssrc = src.gsub("redactor_uploads/#{id}/images","redactor_uploads/#{("%09d" % id).scan(/\d{3}/).join("/")}/images")
                      file = "#{RAILS_ROOT}#{ssrc}".split("?").first
                      if(File.exist? file)
                        p 'copying file to new location'
                        r = RedactorUpload.find(id)
                        p "moving file to #{r.image.path}" if r.update_attribute(:image, File.open(file))
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  #  if(File.directory? 'uploads/redactor_uploads')
  #    FileUtils.rm_r 'uploads/redactor_uploads'
  #  end
else
  p 'Not multischool environment'
end