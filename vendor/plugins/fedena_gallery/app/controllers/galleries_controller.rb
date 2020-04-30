class GalleriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all,:except => [:category_show,:show_image,:download_image,:index]
  filter_access_to [:category_show,:show_image,:download_image,:index], :attribute_check=>true, :load_method => lambda { current_user.parent? ? (current_user.guardian_entry.current_ward.user) : (current_user) }
  check_request_fingerprint :category_edit,:category_update

  def index
    @unpublished_albums=[]
    @admin_mode=false

    @old_albums_present=true

    if current_user.employee?
      @privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
        @has_permission=current_user.privileges.find(@privilege.id)
      end
    end

    #for collecting private album id
    @collected_album_id=[]


    if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
      @all_albums=GalleryCategory.new_data.all(:conditions=>["published=true"],:include=>"gallery_photos")
      @admin_mode=true

      #first three unpublished albums required in view ..
      @unpublished_albums=GalleryCategory.new_data.all(:conditions=>["published=false"],:limit=>3,:order=>"id DESC")
      @unpublished_count=GalleryCategory.new_data.count(:conditions=>["published=false"])
      @old_albums_present=GalleryCategory.old_data.exists?
    else
      #Determine current_user department id  or batch id based on employee or student/parent
      if current_user.student? or current_user.parent?
        # note parent_record gives current_ward of parent
        @student= current_user.student? ? current_user.student_record : current_user.parent_record
        @privilege=@student.gallery_category_privileges
        @collected_album_id=@privilege.collect(&:gallery_category_id)

        any_photo_permission=@student.gallery_tags.first
        if any_photo_permission.present?
          any_photo=GalleryPhoto.old_data.all(:conditions=>["id in (?)", any_photo_permission.gallery_photo_id],:limit=>1)
          if any_photo.count==0
            @old_albums_present=false
          end
        else
          @old_albums_present=false
        end

      end
      #collecting private album id for employees
      if current_user.employee?
        @employee=current_user.employee_record
        @privilege=@employee.gallery_category_privileges
        @collected_album_id=@privilege.collect(&:gallery_category_id)

        any_photo_permission=@employee.gallery_tags.first
        if any_photo_permission.present?
          any_photo=GalleryPhoto.old_data.all(:conditions=>["id in (?)",  any_photo_permission.gallery_photo_id],:limit=>1)
          if any_photo.count==0
            @old_albums_present=false
          end
        else
          @old_albums_present=false
        end
      end

      #add public albums to collected private albums
      @public_albums= GalleryCategory.new_data.all(:conditions => ["visibility = true and published=true"], :include=>"gallery_photos")
      @collected_albums= GalleryCategory.new_data.all(:conditions=>["published=true and id in (?)",@collected_album_id])

      @all_albums=@collected_albums+@public_albums

    end

    @categories=@all_albums
    if @categories.count>1
      @categories.sort! { |x, y| (y.last_modified <=> x.last_modified)  }
    end
    @total_albums=@categories.count
    @categories=@categories.paginate(:per_page=>15,:page=>params[:page])
  end

  def unpublished_albums
    if current_user.employee?
      @privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
        @has_permission=current_user.privileges.find(@privilege.id)
      end
    end
    if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
      #unpublished albums
      @categories=GalleryCategory.new_data.all(:conditions => ["published=false"], :include=>"gallery_photos")
      @categories=@categories.reverse
      @categories=@categories.paginate(:per_page=>15,:page=>params[:page])
    end

  end

  def set_publish
    @category= GalleryCategory.new_data.find(params[:id])
    if @category.gallery_photos.count!=0
      @category.published= @category.published ? false : true
      if @category.published
        @category.published_date=Date.today
        @category.last_modified=DateTime.now
      end
      if @category.save
        button_value=@category.published ? t('galleries.unpublish_album') : t('galleries.publish_album')
        state=@category.published ? t('galleries.published_status_active') : t('galleries.published_status_unpublished')
        published_on= @category.published  ?  "#{t('galleries.published_on')}"+" <b>"+ format_date(@category.published_date).to_s+"</b>" :  "#{t('galleries.created_on')}"+" <b>"+ format_date(@category.created_at.to_date) +"</b>"
        render :json => {"publish_status"=>@category.published, "button_value"=>button_value ,"state"=>state,"set_success"=>true, "published_on"=> published_on }.to_json
      else
        render :json => {"set_success"=>false,"message"=>t('galleries.set_publish_error')}.to_json
      end
    else
      #cannot publish empty album
      render :json => {"set_success"=>false,"message"=>t('galleries.publish_empty_album_error')}.to_json
    end

  end

  def category_new
    dep=EmployeeDepartment.all
    @departments=[]
    dep.each { |e| @n ={}; @n["value"] = e.name ; @n["id"]=e.id; @n["child_count"]=e.employees.count;  @departments << @n}
    @batches=Batch.active
    @values=[]
    @batches.each { |e| @n ={}; @n["value"] = e.full_name ; @n["id"]=e.id; @n["child_count"]=e.students.count; @values << @n}
  end

  def batch_students
    @batch= Batch.find(params[:id]);
    @students=@batch.students;
    @values=[]
    @students.each { |e| @n ={}; @n["value"] = e.full_name_with_admission_no; @n["id"]=e.id; @values << @n}
    render :text => @values.to_json
  end

  def department_employees
    @department= EmployeeDepartment.find(params[:id]);
    @employees=@department.employees;
    @values=[]
    @employees.each { |e| @n ={}; @n["value"] = e.full_name.to_s+" &#x200E;("+e.employee_number.to_s+")&#x200E;"; @n["id"]=e.id; @values << @n}
    render :text => @values.to_json
  end

  def category_create
    @category=GalleryCategory.new()
    #category name .. filter unwanted white space
    @category.name =params[:name].split.join(" ")
    @category.visibility=(params[:visibility]=="public" ? true : false)
    @category.published=false

    if(params[:visibility]=="private")
      @values=JSON.parse(params[:values])
      @collected_student_id=[]

      # two levels for batch
      @values["0"]["b1"]["list"].each_with_index do |element,index|

        if element["selected"]==1
          batch=Batch.find((element["id"]))
          students=batch.students.collect(&:id)
          @collected_student_id=  @collected_student_id+students
        elsif element["selected"]==0
          # do nothing

        else
          @values["1"]["b1"+"b"+index.to_s]["list"].each do |subelement|
            if subelement["selected"]==1
              @collected_student_id=  @collected_student_id<<subelement["id"]
            end
          end
        end

      end

      #for department
      @values=JSON.parse(params[:departments])
      @collected_employee_id=[]

      #two level for departments
      @values["0"]["b1"]["list"].each_with_index do |element,index|
        if element["selected"]==1
          department=EmployeeDepartment.find((element["id"]))
          employees=department.employees.collect(&:id)
          @collected_employee_id=  @collected_employee_id+employees
        elsif element["selected"]==0
          # do nothing

        else
          @values["1"]["b1"+"b"+index.to_s]["list"].each do |subelement|
            if subelement["selected"]==1
              @collected_employee_id=  @collected_employee_id<<subelement["id"]
            end
          end
        end
      end

    end

    if @category.save
      flash[:notice] ="#{t('category_created')}"
      if(params[:visibility]=="private")
        @collected_student_id.each do |e|
          student=Student.find(e);
          @privilege= @category.gallery_category_privileges.build()
          @privilege.imageable_id=student.id
          @privilege.imageable_type=student.class.name
          @privilege.save
        end
        @collected_employee_id.each do |e|
          employee=Employee.find(e);
          @privilege= @category.gallery_category_privileges.build()
          @privilege.imageable_id=employee.id
          @privilege.imageable_type=employee.class.name
          @privilege.save
        end
      end

      render :json => {"success"=>true, "id"=>@category.id}.to_json
    else

      render :json => {"success"=>false, "message"=> @category.errors.full_messages,"session_fingerprint"=>session_fingerprint}.to_json
    end
  end



  def category_show
    @admin_mode=false
    if current_user.employee?
      @privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
        @has_permission=current_user.privileges.find(@privilege.id)
      end
    end
    access=false
    #check if the current_user has access to the album
    if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
      #admin privileges
      access=true
      @admin_mode=true
    else
      #not admin
      album=GalleryCategory.new_data.find(params[:id])
      #check privelege
      if album.visibility and album.published
        #public album and published album
        access=true

      elsif current_user.student? or current_user.parent? or current_user.employee?
        if current_user.student? or current_user.parent?
          @student= current_user.student? ? current_user.student_record : current_user.parent_record
          @privilege=@student.gallery_category_privileges.first(:conditions => ["gallery_category_id = ?",params[:id]])
        elsif current_user.employee?
          @employee=current_user.employee_record
          @privilege=@employee.gallery_category_privileges.first(:conditions => ["gallery_category_id = ?",params[:id]])
        end

        if(!@privilege.nil? and album.published)
          access=true
        end
      end

    end

    if access
      @category=GalleryCategory.new_data.find(params[:id])
      @photos=@category.gallery_photos.alive
      @photos=@photos.reverse
      #keep it safe - auto unpublish
      if(@photos.count==0)
        @category.published=false
        @category.save
      end
      @total_images_count=@photos.count
      @original_images_url=@photos.map{|p| [p.photo.url(:original, false), p.photo.instance.photo_file_name]}
      @per_page=30
      @image_description=@photos.map{|p| (p.description.nil?) ? "" : p.description}
      @photos=@photos.paginate(:per_page=>@per_page,:page=>params[:page])
      @offset=((params[:page]==nil ? 1 : params[:page].to_i)-1)*@per_page
      #published status
      @button_value=@category.published ? t('galleries.unpublish_album') : t('galleries.publish_album')
      #set visibility_tag
      @visibility_tag=""
      if @category.visibility
        @visibility_tag=t('galleries.public')
      else
        student_visibility_count= GalleryCategoryPrivilege.count(:conditions => ["gallery_category_id = ? and imageable_type='Student' ",@category.id])
        employee_visibility_count=GalleryCategoryPrivilege.count(:conditions => ["gallery_category_id = ? and imageable_type='Employee' ",@category.id])
        if student_visibility_count==0 and employee_visibility_count==0
          @visibility_tag= "#{t('galleries.admin')}"
        else
          @visibility_tag="#{"#{student_visibility_count.to_s}  #{student_visibility_count==1 ? t('galleries.student') : t('galleries.students')}" if student_visibility_count!=0}#{"," if student_visibility_count!=0 && employee_visibility_count!=0} #{"#{employee_visibility_count.to_s}  #{employee_visibility_count==1 ? t('galleries.employee') : t('galleries.employees')}" if employee_visibility_count!=0} "
        end
      end

    else
      redirect_to :action=>"index"
    end

  end

  def category_edit
    @category=GalleryCategory.new_data.find(params[:id])
    #--collect all students with access
    privilege_student_ids=@category.gallery_category_privileges.all(:conditions => ["imageable_type = 'Student'"]).collect(&:imageable_id)
    privilege_students=Student.all(:conditions=>["students.id in (?)", privilege_student_ids])
    privilege_students=privilege_students.map {|student| {"id"=>student.id,"value"=>student.full_name_with_admission_no,"selected"=> 1, "batch_id"=>student.batch_id}}
    # students who don't have access
    if(privilege_student_ids.count==0)
      active_students=Student.all
    else
      active_students=Student.all(:conditions=>["students.id not in (?)", privilege_student_ids])
    end


    active_students=active_students.map {|student| {"id"=>student.id,"value"=>student.full_name_with_admission_no,"selected"=> 0 ,"batch_id"=>student.batch_id}}
    all_students = active_students+privilege_students
    #group batches based on courses
    @grouped_students=all_students.group_by { |d| d["batch_id"] }
    level_zero= @grouped_students.map { |key,e| {"id"=>key ,"value"=>Batch.find(key).full_name ,"child_count"=>e.count, "selected"=>0} }
    level_one= {}
    @grouped_students.each do|key, e|
      level_one[key]=e
    end

    @final_values={0=>level_zero,1=>level_one}

    #for department

    #--collect all employees with access
    privilege_employee_ids=@category.gallery_category_privileges.all(:conditions => ["imageable_type = 'Employee'"]).collect(&:imageable_id)
    privilege_employees=Employee.all(:conditions=>["employees.id in (?)", privilege_employee_ids])
    privilege_employees=privilege_employees.map {|employee| {"id"=>employee.id,"value"=>employee.full_name.to_s+" &#x200E;("+employee.employee_number.to_s+")&#x200E;","selected"=> 1, "employee_department_id"=>employee.employee_department_id}}
    # students who don't have access
    if(privilege_employee_ids.count==0)
      active_employees=Employee.all
    else
      active_employees=Employee.all(:conditions=>["employees.id not in (?)", privilege_employee_ids])
    end


    active_employees=active_employees.map {|employee| {"id"=>employee.id,"value"=>employee.full_name.to_s+" &#x200E;("+employee.employee_number.to_s+")&#x200E;","selected"=> 0 ,"employee_department_id"=>employee.employee_department_id}}
    all_employees = active_employees+privilege_employees
    #group batches based on courses
    @grouped_employees=all_employees.group_by { |d| d["employee_department_id"] }
    level_zero= @grouped_employees.map { |key,e| {"id"=>key ,"value"=>EmployeeDepartment.find(key).name ,"child_count"=>e.count, "selected"=>0} }
    level_one= {}
    @grouped_employees.each do|key, e|
      level_one[key]=e
    end

    @final_empployee_values={0=>level_zero,1=>level_one}


  end

  def search_album
    param_words=params[:search][:search_tag].split
    query_string=""

    if param_words.count > 20 or params.length >100
      flash[:notice] ="too long"
      @valid_search=false
    else
      @valid_search=true
      param_words.each_with_index do |word,index|
        query_string=query_string+" name like ? "
        query_string=query_string+" and " if (param_words.count-1) != index
      end

      param_words = param_words.map{|s| "%#{s}%"}
      @categories=GalleryCategory.new_data.all(:conditions => [query_string ]+param_words)
      @total_albums=@categories.count
      @categories=@categories.paginate(:per_page=>15,:page=>params[:page])
    end


  end

  def category_update
    #remove all privilege
    @category=GalleryCategory.new_data.find(params[:id])
    @category.gallery_category_privileges.destroy_all
    #edit other params of category
    @category.name =params[:name]
    @category.visibility=(params[:visibility]=="public" ? true : false)

    #collect privilege
    if(params[:visibility]=="private")
      @values=JSON.parse(params[:values])
      @collected_student_id=[]

      # two levels for batch
      @values["0"]["b1"]["list"].each_with_index do |element,index|

        if element["selected"]==1
          batch=Batch.find((element["id"]))
          students=batch.students.collect(&:id)
          @collected_student_id=  @collected_student_id+students
        elsif element["selected"]==0
          # do nothing

        else
          @values["1"]["b1"+"b"+index.to_s]["list"].each do |subelement|
            if subelement["selected"]==1
              @collected_student_id=  @collected_student_id<<subelement["id"]
            end
          end
        end

      end

      #for department
      @values=JSON.parse(params[:departments])
      @collected_employee_id=[]

      #two level for departments
      @values["0"]["b1"]["list"].each_with_index do |element,index|
        if element["selected"]==1
          department=EmployeeDepartment.find((element["id"]))
          employees=department.employees.collect(&:id)
          @collected_employee_id=  @collected_employee_id+employees
        elsif element["selected"]==0
          # do nothing

        else
          @values["1"]["b1"+"b"+index.to_s]["list"].each do |subelement|
            if subelement["selected"]==1
              @collected_employee_id=  @collected_employee_id<<subelement["id"]
            end
          end
        end
      end

    end

    if @category.save
      flash[:notice] ="#{t('category_updated')}"
      if(params[:visibility]=="private")
        @collected_student_id.each do |e|
          student=Student.find(e);
          @privilege= @category.gallery_category_privileges.build()
          @privilege.imageable_id=student.id
          @privilege.imageable_type=student.class.name
          @privilege.save
        end
        @collected_employee_id.each do |e|
          employee=Employee.find(e);
          @privilege= @category.gallery_category_privileges.build()
          @privilege.imageable_id=employee.id
          @privilege.imageable_type=employee.class.name
          @privilege.save
        end
      end

      render :json => {"success"=>true, "id"=>@category.id}.to_json
    else
      render :json => {"success"=>false, "message"=> @category.errors.full_messages,"session_fingerprint"=>session_fingerprint}.to_json
    end

  end

  def category_delete
    @category=GalleryCategory.find(params[:id])
    @category.delay_destroy
    flash[:notice] ="#{t('successfully_deleted')}"
    if @category.old_data
      redirect_to :action=>"archived_albums"
    else
      redirect_to :action=>"index"
    end

  end

  def edit_photo_description
    @photo=GalleryPhoto.new_data.find(params[:id])
    @photo.description=params[:description]
    result={}
    if @photo.save
      result["status"]= true
      result["description"]=@photo.description
    else
      result["status"]= false
      result["error_message"]="#{t('description_change_error')}"
    end

    render :json=>result.to_json
  end

  def photo_add
    @categories=GalleryCategory.all
    @photo=GalleryPhoto.new
  end

  def photo_create
    @categories=GalleryCategory.new_data.all
    #    @photo=GalleryPhoto.new(params[:photo])
    @photo=GalleryPhoto.new(params[:gallery_photo])
    @photo.gallery_category_id=params[:select_category][:category] unless params[:select_category].nil?
    if @photo.save
      recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
      recipients_array.each do |r|
        employee=Employee.find(r)
        GalleryTag.create(:gallery_photo_id => @photo.id, :member => employee)
      end
      recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
      recipients_array.each do |r|
        student=Student.find(r)
        GalleryTag.create(:gallery_photo_id => @photo.id, :member => student)
      end
      flash[:notice] = "#{t('photo_uploaded')}"

      redirect_to :action=>"category_show",:id=>@photo.gallery_category_id
    else
      @recipients=Employee.find(params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") if params[:recipients].present?
      @recipients1=Student.active.find(params[:recipients1].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC") if params[:recipients1].present?
      @category_id = @photo.gallery_category_id.to_i
      render 'photo_add'
    end
  end

  def add_photo
    @id=params[:id]
    @category=GalleryCategory.new_data.find(@id)
    @photo=@category.gallery_photos.build
  end

  def create_photo
    @category=GalleryCategory.new_data.find((params[:gallery_category]).to_i)
    @photo=@category.gallery_photos.build(params[:gallery_photo])

    if params[:image_name].present?
      #Internet explorer doesnt support file constructor -- so construct file here
      file = Tempfile.new([params[:image_name].to_s,"."+params[:image_extention].to_s])
      begin
        file.write(params[:image].read)
        @photo.photo=file
      ensure
        file.close
        file.unlink
      end

    else
      @photo.photo=params[:image]
    end



    @photo.description=params[:description]
    if @photo.save
      @category.last_modified=DateTime.now
      @category.save
      flash[:notice] = "#{t('photo_uploaded')}"

      render :text=>"success"

    else
      render :text=>"failed"
    end

  end

  def edit_photo
    @photo=GalleryPhoto.find(params[:id])
    @students=Student.find(:all)
    @employees=Employee.find(:all)
    @tags_emp=GalleryTag.find(:all,:conditions=>{:member_type=>"Employee",:gallery_photo_id=>@photo.id}).map{ |s| s.member_id}
    @recipients_emp= @tags_emp.compact.join(',')
    @tags_stu=GalleryTag.find(:all,:conditions=>{:member_type=>"Student",:gallery_photo_id=>@photo.id}).map{ |s| s.member_id}
    @recipients_stu= @tags_stu.compact.join(',')
    @recipients=Employee.find_all_by_id(@recipients_emp.split(",")).sort_by{|a| a.full_name.downcase}
    @recipients1=Student.find_all_by_id(@recipients_stu.split(",")).sort_by{|a| a.full_name.downcase}
    if request.post?
      if @photo.update_attributes(params[:photo])
        @flag=0
        recipients_emp = params[:recipients_emp].split(",").collect{ |s| s.to_i }
        recipients_stu = params[:recipients_stu].split(",").collect{ |s| s.to_i }
        recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
        recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
        recipients_emp.each do |r|
          employee=Employee.find(r)
          tag=GalleryTag.find(:all,:conditions=>{:gallery_photo_id => @photo.id, :member_id => employee,:member_type=>"Employee"}).first
          tag.destroy
        end
        recipients_stu.each do |r|
          student=Student.find(r)
          tag=GalleryTag.find(:all,:conditions=>{:gallery_photo_id => @photo.id, :member_id => student,:member_type=>"Student"}).first
          tag.destroy
        end

        recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
        recipients_array.each do |r|
          employee=Employee.find(r)
          GalleryTag.create(:gallery_photo_id => @photo.id, :member => employee)
        end
        recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
        recipients_array.each do |r|
          student=Student.find(r)
          GalleryTag.create(:gallery_photo_id => @photo.id, :member => student)
        end
        flash[:notice] = "#{t('photo_updated')}"
        redirect_to :action=>"category_show",:id=>@photo.gallery_category_id
      else
        @recipients=Employee.find(params[:recipients].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC")
        @recipients1=Student.active.find(params[:recipients1].split(",").reject{|a| a.strip.blank?}.collect{ |s| s.to_i },:order=>"first_name ASC")
        render 'edit_photo'
      end
    end
  end


  def photo_delete
    @photo=GalleryPhoto.new_data.find(params[:id])
    @category=GalleryCategory.new_data.find(@photo.gallery_category_id)
    @photo.delay_destroy
    #remaining photos
    @photos=@category.gallery_photos.alive.reverse
    @photos_count=@photos.count
    @original_images_url=@photos.map{|p| p.photo.url(:original, false)}
    @image_description=@photos.map{|p| (p.description.nil?) ? "" : p.description}
    if params[:page]!="1" and @photos.paginate(:per_page=>30,:page=>params[:page]).count==0
      @photos=@photos.paginate(:per_page=>30,:page=>(params[:page].to_i-1))
    else
      @photos=@photos.paginate(:per_page=>30,:page=>params[:page])
    end

    if @photos.count==0
      @category.published=false
      @category.save
    end

    #flash[:notice] ="#{t('successfully_deleted')}"
    render :update do |page|
      page.replace_html 'album_images', :partial => 'photos_after_delete'
      page.replace_html 'photos_count', :text => @photos_count
      page.replace_html 'publish_button', :text => ( @category.published ? t('galleries.unpublish_album') : t('galleries.publish_album'))
      page.replace_html 'published_status', :text => (@category.published ? t('galleries.published_status_active') : t('galleries.published_status_unpublished'))
    end

  end

  def download_image
    if GalleryPhoto.find(params[:id]).old_data?
      #for old_album---------------------------------------------------------------------
      old_access=false
      photo=GalleryPhoto.old_data.find(params[:id])

      if current_user.employee?
        @old_privilege=Privilege.find_by_name("Gallery")
        if current_user.privileges.find(:all, :conditions=>{:id=>@old_privilege.id}).present?
          @old_has_permission=current_user.privileges.find(@privilege.id)
        end
      end
      #check if the current_user has access to the album
      if current_user.admin? or @old_has_permission.present? or current_user.has_gallery_privileges?
        #admin privileges
        old_access=true
      else
        #not admin
        if current_user.student? or current_user.parent? or current_user.employee?
          if current_user.student? or current_user.parent?
            student= current_user.student? ? current_user.student_record : current_user.parent_record
            @old_privilege=student.gallery_tags.first(:conditions=>["gallery_photo_id=?",photo.id])

          elsif current_user.employee?

            employee=current_user.employee_record
            @old_privilege=employee.gallery_tags.first(:conditions=>["gallery_photo_id=?",photo.id])
          end
          if(!@old_privilege.nil?)
            old_access=true
          end
        end

      end

      if old_access==true
        file=GalleryPhoto.old_data.find(params[:id])
        if params[:style].to_s=="thumb"
          send_file file.photo.path(:thumb), :type => file.photo_content_type, :disposition => 'inline'
        elsif params[:style].to_s=="small"
          #sending thumb... as for old gallery :small was tooo small
          send_file file.photo.path(:thumb), :type => file.photo_content_type, :disposition => 'inline'
        else
          send_file file.photo.path, :type => file.photo_content_type, :disposition => 'inline'
        end
      end

    else
      #for new album-------------------------------------------------------------------------------
      album_id=(GalleryPhoto.new_data.find(params[:id])).gallery_category_id

      @admin_mode=false
      if current_user.employee?
        @privilege=Privilege.find_by_name("Gallery")
        if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
          @has_permission=current_user.privileges.find(@privilege.id)
        end
      end
      access=false
      #check if the current_user has access to the album
      if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
        #admin privileges
        access=true
        @admin_mode=true
      else
        #not admin
        album=GalleryCategory.new_data.find(album_id)
        #check privelege
        if album.visibility and album.published
          #public album and published album
          access=true

        elsif current_user.student? or current_user.parent? or current_user.employee?
          if current_user.student? or current_user.parent?
            @student= current_user.student? ? current_user.student_record : current_user.parent_record
            @privilege=@student.gallery_category_privileges.first(:conditions => ["gallery_category_id = ?",album_id])

          elsif current_user.employee?

            @employee=current_user.employee_record
            @privilege=@employee.gallery_category_privileges.first(:conditions => ["gallery_category_id = ?",album_id])
          end
          if(!@privilege.nil? and album.published)
            access=true
          end
        end

      end

      if access
        file=GalleryPhoto.new_data.find(params[:id])
        if params[:style].to_s=="thumb"
          send_file file.photo.path(:thumb), :type => file.photo_content_type, :disposition => 'inline'
        elsif params[:style].to_s=="small"
          send_file file.photo.path(:small), :type => file.photo_content_type, :disposition => 'inline'
        else
          send_file file.photo.path, :type => file.photo_content_type, :disposition => 'inline'
        end
      end
    end


  end


  def show_image
    file=GalleryPhoto.find(params[:id])
    send_file file.photo.path(:thumb), :type => file.photo_content_type, :disposition => 'inline'
  end

  def select_employee_department
    @user = current_user
    @departments = EmployeeDepartment.active_and_ordered
    render :partial=>"select_employee_department"
  end

  def select_users
    @user = current_user
    users = User.active.find(:all, :conditions=>"student = false")
    @to_users = users.map { |s| s.id unless s.nil? }
    render :partial=>"to_users", :object => @to_users
  end

  def select_student_course
    @user = current_user
    @batches = Batch.active
    render :partial=> "select_student_course"
  end

  def to_employees
    unless params[:dept_id] == ""
      department = EmployeeDepartment.find(params[:dept_id])
      employees  = department.employees.all(:order => "first_name")
      @to_users = employees.map { |s| s.id unless s.nil? }
      render :update do |page|
        page.replace_html 'to_users', :partial => 'to_users'
      end
    else
      render :update do |page|
        page.replace_html "to_users", :text => ""
      end
    end
  end

  def to_students
    unless params[:batch_id] == ""
      batch = Batch.find(params[:batch_id])
      students = batch.students.all(:order => "first_name")
      @to_users = students.map { |s| s.id unless s.nil? }
      @to_users.delete nil
      render :update do |page|
        page.replace_html 'to_users2', :partial => 'to_users_1', :object => @to_users
      end
    else
      render :update do |page|
        page.replace_html "to_users2", :text => ""
      end
    end
  end

  def update_recipient_list
    if params[:recipients]
      @recipients_array = params[:recipients].split(",").collect{ |s| s.to_i }
      @recipients = Employee.find_all_by_id(@recipients_array.uniq).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list', :partial => 'recipient_list'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def update_recipient_list1
    if params[:recipients1]
      @recipients_array = params[:recipients1].split(",").collect{ |s| s.to_i }
      @recipients1 = Student.find(@recipients_array).sort_by{|a| a.full_name.downcase}
      render :update do |page|
        page.replace_html 'recipient-list1', :partial => 'recipient_list_1'
      end
    else
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def more_option
    @id=params[:id]
    @category=@category=GalleryCategory.find(@id)
    @count = @category.gallery_photos.alive.count

    @visibility_tag=""
    if @category.visibility
      @visibility_tag=t('galleries.public')
    else
      student_visibility_count= GalleryCategoryPrivilege.count(:conditions => ["gallery_category_id = ? and imageable_type='Student' ",@category.id])
      employee_visibility_count=GalleryCategoryPrivilege.count(:conditions => ["gallery_category_id = ? and imageable_type='Employee' ",@category.id])
      if student_visibility_count==0 and employee_visibility_count==0
        @visibility_tag= "#{t('galleries.admin')}"
      else
        @visibility_tag="#{"#{student_visibility_count.to_s}  #{student_visibility_count==1 ? t('galleries.student') : t('galleries.students')}" if student_visibility_count!=0}#{"," if student_visibility_count!=0 && employee_visibility_count!=0} #{"#{employee_visibility_count.to_s}  #{employee_visibility_count==1 ? t('galleries.employee') : t('galleries.employees')}" if employee_visibility_count!=0} "
      end
    end
  end


  def archived_albums
    if current_user.employee?
      @privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
        @has_permission=current_user.privileges.find(@privilege.id)
      end
    end
    if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
      @categories=GalleryCategory.old_data.find(:all)
      @photos=GalleryPhoto.old_data
      @grouped_photos=@photos.group_by(&:gallery_category_id)
    else
      if current_user.student?
        @student=current_user.student_record
        @tags=GalleryTag.all(:conditions=>{:member_type=>"Student", :member_id=> @student.id})
        #@tags=@student.gallery_tags
        @images=GalleryPhoto.old_data.find(@tags.map {|s| s.gallery_photo_id})
        @categories=GalleryCategory.old_data.find(@images.map {|s| s.gallery_category_id})
        #thumbs for albums
        @old_album_ids=@student.gallery_tags.all.collect(&:gallery_photo_id)
        @photos=GalleryPhoto.old_data.all(:conditions=>[" id in (?)",@old_album_ids])
        @grouped_photos=@photos.group_by(&:gallery_category_id)
      elsif current_user.parent?
        @student= current_user.guardian_entry.current_ward
        @tags=GalleryTag.all(:conditions=>{:member_type=>"Student", :member_id=> @student.id})
        #@tags=@student.gallery_tags
        @images=GalleryPhoto.old_data.find(@tags.map {|s| s.gallery_photo_id})
        @categories=GalleryCategory.old_data.find(@images.map {|s| s.gallery_category_id})
        #thumbs for album
        @old_album_ids=@student.gallery_tags.all.collect(&:gallery_photo_id)
        @photos=GalleryPhoto.old_data.all(:conditions=>[" id in (?)",@old_album_ids])
        @grouped_photos=@photos.group_by(&:gallery_category_id)
      elsif current_user.employee?
        @employee=current_user.employee_record
        @tags=GalleryTag.all(:conditions=>{:member_type=>"Employee", :member_id=> @employee.id})
        #@tags=@employee.gallery_tags
        @images=GalleryPhoto.old_data.find(@tags.map {|s| s.gallery_photo_id})
        @categories=GalleryCategory.old_data.find(@images.map {|s| s.gallery_category_id})
        #thumbs for album
        @old_album_ids=@employee.gallery_tags.all.collect(&:gallery_photo_id)
        @photos=GalleryPhoto.old_data.all(:conditions=>[" id in (?)",@old_album_ids])
        @grouped_photos=@photos.group_by(&:gallery_category_id)
      else
        puts "USER determination failed"
      end
    end
    @categories=@categories.reverse
    @total_albums=@categories.count

    # if current page is empty -> go to first page
    if @categories.paginate(:per_page=>15,:page=>params[:page]).count==0 and params[:page].to_i > 1
      @categories=@categories.paginate(:per_page=>15,:page=>1)
    else
      @categories=@categories.paginate(:per_page=>15,:page=>params[:page])
    end


  end

  def old_category_show
    @admin_mode=false
    @category=GalleryCategory.old_data.find(params[:id])
    if current_user.employee?
      @old_privilege=Privilege.find_by_name("Gallery")
      if current_user.privileges.find(:all, :conditions=>{:id=>@old_privilege.id}).present?
        @old_has_permission=current_user.privileges.find(@privilege.id)
      end
    end
    #check if the current_user has access to the album
    if current_user.admin? or @old_has_permission.present? or current_user.has_gallery_privileges?
      #admin privileges
      @admin_mode=true
      @photos=@category.gallery_photos.old_data
    else
      #not admin
      if current_user.student? or current_user.parent? or current_user.employee?
        if current_user.student? or current_user.parent?
          student= current_user.student? ? current_user.student_record : current_user.parent_record
          @old_photo_ids=student.gallery_tags.all.collect(&:gallery_photo_id)
          @photos=GalleryPhoto.old_data.all(:conditions=>["gallery_category_id = ? and id in (?)",@category.id,@old_photo_ids])
        elsif current_user.employee?
          employee=current_user.employee_record
          @old_photo_ids=employee.gallery_tags.all.collect(&:gallery_photo_id )
          @photos=GalleryPhoto.old_data.all(:conditions=>["gallery_category_id = ? and id in (?)",@category.id,@old_photo_ids])
        end
      end
    end

    @total_images_count=@photos.count
    if @photos.count !=0
      @photos=@photos.reverse
      @original_images_url=@photos.map{|p| p.photo.url(:original, false)}
      @per_page=30
      @image_description=@photos.map{|p| (p.name.nil?) ? "" : p.name}
      @photos=@photos.paginate(:per_page=>@per_page,:page=>params[:page])
      @offset=((params[:page]==nil ? 1 : params[:page].to_i)-1)*@per_page

    else
      if !@admin_mode
        redirect_to :action=>"archived_albums"
      end

    end

  end

  def old_photo_delete
    @photo=GalleryPhoto.old_data.find(params[:id])
    @category=GalleryCategory.old_data.find(@photo.gallery_category_id)
    @photo.delay_destroy
    #remaining photos
    @photos=@category.gallery_photos.alive.reverse
    @photos_count=@photos.count
    @original_images_url=@photos.map{|p| p.photo.url(:original, false)}

    @image_description=@photos.map{|p| (p.name.nil?) ? "" : p.name}
    if params[:page]!="1" and @photos.paginate(:per_page=>30,:page=>params[:page]).count==0
      @photos=@photos.paginate(:per_page=>30,:page=>(params[:page].to_i-1))
    else
      @photos=@photos.paginate(:per_page=>30,:page=>params[:page])
    end

    if @photos.count==0
      @category.published=false
      @category.save
    end


    #flash[:notice] ="#{t('successfully_deleted')}"
    render :update do |page|
      page.replace_html 'album_images', :partial => 'old_photos_after_delete'
      page.replace_html 'photos_count', :text => @photos_count
    end

  end

  def delete_multiple_photos
    @category=GalleryCategory.find(params[:id])

    if params[:count]=="0"
      if current_user.employee?
        @privilege=Privilege.find_by_name("Gallery")
        if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
          @has_permission=current_user.privileges.find(@privilege.id)
        end
      end
      if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
        @photos=@category.gallery_photos.alive
      end

      @photos=@photos.reverse
      @total_album_images=@photos.count
      @photos=@photos.paginate(:per_page=>30,:page=>params[:page])
      #first time load - delete set empty
      render :partial=>"multiple_photos_select", :locals => {:photos =>@photos}
    else
      #after delete render
      GalleryPhoto.delay_destroy(params[:delete_images_id])
      if @category.gallery_photos.alive.count==0
        @category.published=false
        @category.save
      end

      if current_user.employee?
        @privilege=Privilege.find_by_name("Gallery")
        if current_user.privileges.find(:all, :conditions=>{:id=>@privilege.id}).present?
          @has_permission=current_user.privileges.find(@privilege.id)
        end
      end
      if current_user.admin? or @has_permission.present? or current_user.has_gallery_privileges?
        @photos=@category.gallery_photos.alive
      end
      @photos=@photos.reverse
      @total_album_images=@photos.count
      #empty album gets unpublished
      if(@total_album_images==0)
        @category.published=false
        @category.save
      end
      @photos=@photos.paginate(:per_page=>30,:page=>params[:page])
      render :partial=>"multiple_photos_select", :locals => {:photos =>@photos}
    end
  end

end
