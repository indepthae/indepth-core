class MasterFeesController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  before_filter :check_if_linking_required

  require 'lib/override_errors'
  helper OverrideErrors

  check_request_fingerprint :create_master_particulars, :update_master_particular, :delete_master_particular,
                            :create_master_discounts, :update_master_discount, :delete_master_discount
  @@per_page = 10

  # view / manage
  # 1. master fee particular
  # 2. master fee discount
  def index
    unless request.xhr?
      load_particulars
      load_discounts
    else
      case params[:to_fetch]
        when 'particulars'
          load_particulars
        when 'discounts'
          load_discounts
      end
      xhr_render "#{params[:to_fetch]}_list", "master_#{params[:to_fetch]}"
    end
  end

  def new_master_particular
    if request.xhr? and request.post?
      @particular = MasterFeeParticular.new
      render_form @particular
    else
      xhr_redirect_dashboard
    end
  end

  def create_master_particular
    if request.xhr? and request.post?
      @particular = MasterFeeParticular.new(param)
      if @particular.save
        flash[:notice] = t('flash_p1')
        xhr_redirect_index
      else
        render_form @particular
      end
    else
      xhr_redirect_dashboard
    end
  end

  def edit_master_particular
    if request.xhr?
      @particular = MasterFeeParticular.find(params[:id])
      render_form @particular
    else
      xhr_redirect_dashboard
    end
  rescue
    flash[:notice] = t('record_not_found')
    xhr_redirect_dashboard
  end

  def update_master_particular
    if request.xhr? and request.put?
      @particular = MasterFeeParticular.find(params[:id])
      if @particular.update_attributes(param)
        flash[:notice] = t('flash_p2')
        xhr_redirect_index
      else
        render_form @particular
      end
    else
      xhr_redirect_dashboard
    end
  end

  def delete_master_particular
    if request.xhr? and request.delete?
      particular = MasterFeeParticular.find(params[:id])
      flash[:notice] = particular.destroy ? t('flash_p3') : t('flash_p4')
      xhr_redirect_index
    else
      xhr_redirect_dashboard
    end
  end

  def new_master_discount
    if request.xhr? and request.post?
      @discount = MasterFeeDiscount.new
      render_form @discount
    else
      xhr_redirect_dashboard
    end
  end

  def create_master_discount
    if request.xhr? and request.post?
      @discount = MasterFeeDiscount.new(param)
      if @discount.save
        flash[:notice] = t('flash_d1')
        xhr_redirect_index
      else
        render_form @discount
      end
    else
      xhr_redirect_dashboard
    end
  end

  def edit_master_discount
    if request.xhr?
      @discount = MasterFeeDiscount.find(params[:id])
      render_form @discount
    else
      xhr_redirect_dashboard
    end
  end

  def update_master_discount
    if request.xhr? and request.put?
      @discount = MasterFeeDiscount.find(params[:id])
      if @discount.update_attributes(param)
        flash[:notice] = t('flash_d2')
        xhr_redirect_index
      else
        render_form @particular
      end
    else
      xhr_redirect_dashboard
    end
  end

  def delete_master_discount
    if request.xhr? and request.delete?
      discount = MasterFeeDiscount.find(params[:id])
      flash[:notice] = discount.destroy ? t('flash_d3') : t('flash_d4')
      xhr_redirect_index
    else
      xhr_redirect_dashboard
    end
  end

  # manage / link mechanism for old finance fee particulars / fee discounts
  # Note: 1. currently disabled [because of load]
  #       2. enable auths to renable same.
  #       3. this is working and tested [optimized after load issues]
  def manage_masters
    if request.post?
      @cat_type ||= param[:fee_type]
      @cat_types ||= param[:fee_types] || @cat_type.to_a
      # @fee_type = params[:fee_type]
      mapping_masters

      fetch_categories if @cat_type.present? and ['core', 'instant'].include?(@cat_type)

      additional_params = Hash.new
      additional_params[:fee_type] = params[:fee_type]
      additional_params[:student_id] = params[:student_id] if params[:student_id].present?
      additional_params[:batch_id] = params[:batch_id] if params[:batch_id].present?
      additional_params[:cat_id] = params[:cat_id] if params[:cat_id].present?

      render :update do |page|
        page.redirect_to({:action => "manage_masters"}.merge(additional_params))
        #   page.replace_html 'fee_categories', :partial => 'fee_categories'
        #   page.replace_html 'masters_data', :text => ''
      end
    else
      @particulars = Hash.new { |h, k| h[k] = Array.new }
      @fee_type = params[:fee_type]
      @master_particulars = MasterFeeParticular.core if @fee_type == 'pay_all' || @fee_type == 'core' || @fee_type == 'instant'
      @master_discounts = MasterFeeDiscount.core if @fee_type == 'pay_all' || @fee_type == 'core' || @fee_type == 'transport'
      if params[:fee_type] == 'pay_all'
        if params[:student_id].present?
          @student = Student.find(params[:student_id])
          @batch = params[:batch_id] ? Batch.find(params[:batch_id]) : @student.batch
          @categorized_particulars = MasterFeeParticular.fetch_unlinked_particulars({:student_id => @student.id,
                                                                                     :batch_id => @batch.id})
          @categorized_discounts = MasterFeeDiscount.fetch_unlinked_discounts({:student_id => @student.id,
                                                                               :batch_id => @batch.id})
          # @categorized_discounts = MasterFeeDiscount.fetch_unlinked_discounts @student.id, @batch.id
        else
          # redirect to dashboard
        end
      elsif params[:fee_type] == 'core'
        if !(FinanceFeeParticular.has_unlinked_particulars?(params[:cat_id]) or FeeDiscount.has_unlinked_discounts?(params[:cat_id]))
          # redirect to dashboard if nothing to map
        else
          @category = FinanceFeeCategory.find(params[:cat_id])
          @categorized_particulars = MasterFeeParticular.fetch_unlinked_particulars({:cat_id => @category.id, :cat_type => 'core'})
          @categorized_discounts = MasterFeeDiscount.fetch_unlinked_discounts({:cat_id => @category.id, :cat_type => 'core'})
          # particulars = FinanceFeeParticular.for_category(params[:cat_id]).without_masters.all(:order => "name asc")
          # if particulars.present?
          #   particulars.each { |x| @particulars[x.name.capitalize] << x.id }
          #   @master_particulars = MasterFeeParticular.core
          # end
        end
        elsif params[:fee_type] == 'instant'
          unless InstantFeeCategory.has_unlinked_particulars?(params[:cat_id])
            # redirect to dashboard if nothing to map
          else
            @category = InstantFeeCategory.find(params[:cat_id])
            # particulars = InstantFeeParticular.for_category(params[:cat_id]).without_masters.all(:order => "name asc")
            # if particulars.present?
            #   particulars.each { |x| @particulars[x.name.capitalize] << x.id }
            #   @master_particulars = MasterFeeParticular.core
            # end
            @categorized_particulars = MasterFeeParticular.fetch_unlinked_particulars({:cat_id => @category.id, :cat_type => 'instant'})
          end
      elsif params[:fee_type] == 'hostel'
        unless HostelFeeCollection.has_unlinked_collections?
          # redirect to dashboard if nothing to map
        else

        end
      elsif params[:fee_type] == 'transport'
        unless TransportFeeCollection.has_unlinked_collections?
          # redirect to dashboard if nothing to map
        else

        end
      elsif params[:fee_type] == 'registration' # applicant registration
        unless RegistrationCourse.has_unlinked_courses?
          # redirect to dashboard if nothing to map
        else

        end
      else
        # redirect to master fees dashboard if no linking required else show page with choice of fee type etc
      end
      # if param.present?
      #
      # else
      #
      # end
    end
  end

  def load_categories
    @cat_type ||= params[:type]
    fetch_categories
    render :update do |page|
      page.replace_html 'fee_categories', :partial => 'fee_categories'
      page.replace_html 'masters_data', :text => ''
    end
  end

  def load_fee_particulars
    @particulars = Hash.new { |h, k| h[k] = Array.new }
    @discounts = Hash.new { |h, k| h[k] = Array.new }
    @cat_id = params[:id]
    @cat_type = params[:type]
    if params[:type] == 'core'
      particulars = FinanceFeeParticular.for_category(params[:id]).without_masters.all(:order => "name asc", :limit => 500)
      discounts = FeeDiscount.for_category(params[:id]).without_masters.all(:order => "name asc", :limit => 500)
    elsif params[:type] == 'instant'
      particulars = InstantFeeParticular.for_category(params[:id]).without_masters.all(:order => "name asc", :limit => 500)
      discounts = []
    else
      particulars = []
      discounts = []
    end

    if particulars.present?
      particulars.each { |x| @particulars[x.name.capitalize] << x.id }
      @master_particulars = MasterFeeParticular.core
    end

    if discounts.present?
      discounts.each { |x| @discounts[x.name.capitalize] << x.id }
      @master_discounts = MasterFeeDiscount.core
    end

    render :update do |page|
      flash.now[:notice] = t('master_fees.no_discounts_particulars') if !(particulars.present? or discounts.present?)
      page.replace_html 'fee_particulars', :partial => ((particulars.present? or discounts.present?)? "fee_particulars_and_discounts" : "flash_notice")
      page.replace_html 'masters_data', :text => ''
    end
  end

  private

  def check_if_linking_required
    if request.get?
      if params[:fee_type] == 'pay_all'
        @student = Student.find(params[:student_id])
        @batch = Batch.find(params[:batch_id] || @student.batch_id)
        status_1, msg_1 = MasterFeeParticular.has_unlinked_particulars?(@student.id, @batch.id)
        status_2, msg_2 = MasterFeeDiscount.has_unlinked_discounts?(@student.id, @batch.id)
        if !status_1 or !status_2
          flash[:notice] = ""
          flash[:notice] += t("master_fees.#{msg_1}") unless status_1
          flash[:notice] += t("master_fees.#{msg_2}") unless status_2
          flash[:notice] = t('linking_not_required_for_student', {:student_name => @student.full_name})
          redirect_to master_fees_path
        end
      elsif params[:fee_type] == 'core'
        status_1 = FinanceFeeParticular.has_unlinked_particulars?(params[:cat_id])
        status_2 = FeeDiscount.has_unlinked_discounts?(params[:cat_id])
        if !status_1 and !status_2
          # flash[:notice] = ""
          # flash[:notice] += t("master_fees.#{msg_1}") unless status_1
          # flash[:notice] += t("master_fees.#{msg_2}") unless status_2
          redirect_to master_fees_path
        end
      elsif params[:fee_type] == 'transport'
        status = TransportFeeCollection.has_unlinked_collections?
        # status_2, msg_2 = MasterFeeDiscount.has_unlinked_discounts?(params[:student_id], params[:batch_id])
        unless status #or !status_2
          # flash[:notice] = ""
          # flash[:notice] += t("master_fees.#{msg_1}") unless status_1
          # flash[:notice] += t("master_fees.#{msg_2}") unless status_2
          redirect_to master_fees_path
        end
      elsif params[:fee_type] == 'hostel'
        status = HostelFeeCollection.has_unlinked_collections?
        # status_2, msg_2 = MasterFeeDiscount.has_unlinked_discounts?(params[:student_id], params[:batch_id])
        unless status #or !status_2
          # flash[:notice] = ""
          # flash[:notice] += t("master_fees.#{msg_1}") unless status_1
          # flash[:notice] += t("master_fees.#{msg_2}") unless status_2
          redirect_to master_fees_path
        end
      else

      end
    end
  end

  def mapping_masters
    # @cat_types.each do |cat_type|
    #   case @cat_type
    #     when 'hostel'
    #
    #     when 'instant'
    #
    #     when 'transport'
    #
    #     when 'registration'
    #
    #     when 'core'
    #   end
    # end
    #update particulars linking
    status_1, msg_1 = MasterFeeParticular.link_particulars(param[:particulars]) if param[:particulars].present?
    #update discounts linking
    status_2, msg_2 = MasterFeeDiscount.link_discounts(param[:discounts]) if param[:discounts].present?
    # puts "updating attempt"
    # puts status_1
    # puts msg_1
    # puts status_2
    # puts msg_2

    flash_msg = []
    flash_msg << t('master_fees.no_particulars_selected') if !param[:particulars].present? and !param[:discounts].present?

    # flash_msg << t("master_fees.#{msg_1}") if !status_1 and msg_1 == 'no_particulars_selected'
    # flash_msg << t("master_fees.#{msg_2}") if !status_2 and msg_2 == 'no_particulars_selected'
    # flash_msg << (status_1 && status_2) ? t('master_fees.flash_1') : t('master_fees.flash_2') if (status_1 && status_2)

    flash_msg << t("master_fees.#{msg_1}") if status_1
    flash_msg << t("master_fees.#{msg_2}") if status_2

    flash_msg.compact!

    flash[:notice] = flash_msg.join(', ') if flash_msg.present?
    # flash.disc .clear if flash[:notice] == ""
  end

  def fetch_categories
    @cat_type ||= params[:type]
    if @cat_type == 'core'
      @fee_categories = FinanceFeeCategory.all(
          :joins => "INNER JOIN finance_fee_particulars ffp ON ffp.finance_fee_category_id = finance_fee_categories.id",
          :conditions => "ffp.master_fee_particular_id IS NULL", :group => "finance_fee_categories.id")
      @fee_categories += FinanceFeeCategory.all(
          :joins => "INNER JOIN fee_discounts fd ON fd.finance_fee_category_id = finance_fee_categories.id",
          :conditions => "fd.master_fee_discount_id IS NULL", :group => "finance_fee_categories.id")
      @fee_categories = @fee_categories.uniq.sort_by {|x| x.name }
    elsif @cat_type == 'instant'
      @fee_categories = InstantFeeCategory.all(
          :joins => "INNER JOIN instant_fee_particulars ifp ON ifp.instant_fee_category_id = instant_fee_categories.id",
          :conditions => "ifp.master_fee_particular_id IS NULL", :group => "instant_fee_categories.id")
    end
  end

  def param
    (
    case action_name
      when 'create_master_particular'
        params[:master_fee_particular].slice(:name, :description)

      when 'update_master_particular'
        params[:master_fee_particular].slice(:name, :description)
      when 'create_master_discount'
        params[:master_fee_discount].slice(:name, :description)
      when 'update_master_discount'
        params[:master_fee_discount].slice(:name, :description)
      when 'manage_masters'
        params[:manage_masters]
    end) || {}

  end


  def load_particulars
    @master_particulars = MasterFeeParticular.core.load_dependencies.order_by_name.
        paginate(:per_page => @@per_page, :page => params[:page])
  end

  def load_discounts
    @master_discounts = MasterFeeDiscount.core.load_dependencies.order_by_name.
        paginate(:per_page => @@per_page, :page => params[:page])
  end

  def render_form obj
    obj_name = obj.class.name.underscore
    render :update do |page|
      page << "build_modal_box({'title' : '#{obj.new_record? ? t("create_#{obj_name}") :
          t("edit_#{obj_name}")}'})" unless params[obj_name.to_sym].present?
      page.replace_html 'popup_content', :partial => "#{obj_name}_form"
    end
  end

  def xhr_render to_replace, partial
    render :update do |page|
      page.replace_html to_replace.to_sym, :partial => partial
    end
  end

  def xhr_redirect_index
    render :update do |page|
      page.redirect_to master_fees_path
    end
  end

  def xhr_redirect_dashboard
    render :update do |page|
      flash[:notice] ||= t('flash_msg5')
      page.redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def redirect_dashboard
    flash[:notice] = t('flash_msg5')
    redirect_to :controller => "user", :action => "dashboard"
  end

end
