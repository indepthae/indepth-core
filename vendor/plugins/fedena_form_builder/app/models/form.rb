class Form < ActiveRecord::Base
  has_many		:form_submissions, :dependent => :destroy
  belongs_to  :form_template
  belongs_to  :user
  has_and_belongs_to_many :viewers, :class_name => 'User'
  has_and_belongs_to_many :form_targets, :class_name => 'User', :join_table => 'form_targets_users'
  attr_accessor :members,:students,:targets,:disabled_members,:disabled_targets
  attr_accessor :fields_missing
  validates_presence_of :name
  named_scope :feedback_forms, :conditions => {:is_closed => false, :is_feedback => true}, :order => "updated_at DESC"
  named_scope :public_forms, :conditions => {:is_closed => false, :is_public => true}, :order => "updated_at DESC"
  named_scope :active_forms, :conditions => {:is_closed => false}, :order => "updated_at DESC"
  named_scope :general_forms, :conditions => {:is_closed => false, :is_feedback => false}, :order => "updated_at DESC"
  named_scope :updated_order, :order => "updated_at DESC"
  #  default_scope :order => "updated_at DESC"

  def validate
    if(self.is_feedback)
      errors.add(:base, t('members_must_feedback')) if !self.members.present?
      errors.add(:base, t('targets_must_feedback_targeted')) if !self.targets.present? and self.is_targeted
    elsif(!self.is_public)
      errors.add(:base, t('members_must_private')) if !self.members.present?
    end
  end

  def allowed_to_submit? current_user
    flag = false
    if(!self.is_closed)
      if(self.is_feedback)	## feedback form
        uids = [current_user.guardian_entry.current_ward.user_id] if current_user.parent
        ##s.collect{|x| x.user_id} if current_user.parent
        uids = [current_user.id] if !current_user.parent
        tids = self.net_targets(current_user)
        if(self.is_targeted)
          if(tids.present?)
            if current_user.parent
              tids = self.form_target_ids
              vids = self.viewer_ids
              scount = 0
              if(vids.include? uids.first)
                scount = current_user.form_submissions.all(:conditions => ['form_id = ? and ward_id = ? and target IN (?)',self.id,uids.first,tids.join(',')]).count
              else
                flag = false
              end
              flag = scount < tids.count ? true : false
            else
              flag = ((self.viewer_ids & uids).present? and tids.present?) ? true : false
            end
          end
        else
          if current_user.parent
            flag = !current_user.form_submissions.all(:conditions => ['form_id = ? and ward_id = ?',self.id,uids.first]).present?
          else
            flag = !current_user.form_submissions.all(:conditions => ['form_id = ?',self.id]).present?
          end
        end
      elsif(self.is_public)	## public form
        if(self.is_multi_submitable)
          flag = true
        else
          if current_user.parent
            uids = [current_user.guardian_entry.current_ward.user_id] if current_user.parent
            flag = !current_user.form_submissions.all(:conditions => ['form_id = ? and ward_id = ?',self.id,uids.first]).present?
          else
            flag =  (!current_user.form_submissions.all(:conditions=>{:form_id=>self.id}).present?) ? true : false
          end
        end
      elsif(!self.is_public)	## private form
        #        uids = current_user.guardian_entry.wards.collect{|x| x.user_id} if current_user.parent
        uids = [current_user.guardian_entry.current_ward.user_id] if current_user.parent
        uids = [current_user.id] if !current_user.parent

        if(self.is_multi_submitable)
          flag = (self.viewer_ids & uids).present? ? true : false
        elsif(current_user.parent and (self.viewer_ids & uids).present? and !current_user.form_submissions.all(:conditions=>['form_id = ? and ward_id = ? ',self.id,uids.first]).present?)          
          if(self.is_parent == 0 or self.is_parent == 2)
            flag = true
          end
        elsif(!current_user.form_submissions.all(:conditions=>{:form_id=>self.id}).present? and (self.viewer_ids & uids).present?)
          if(current_user.student and (self.is_parent == 1 or self.is_parent == 2))
            flag = true
          elsif(!current_user.student and !current_user.parent)
            flag = true
          else
            flag = false
          end
        else
          flag = false
        end
      end

    else ## give suitable error
      flag = false
    end
    return flag
  end

  def is_already_submitted? current_user
    flag = true
    if !self.is_closed
      if(self.is_public) ## public form
        flag = false unless self.is_multi_submitable
      elsif(!self.is_public) ## private form
        if current_user.parent          
          wid = current_user.guardian_entry.current_ward.user_id
          vids = self.viewer_ids
          if vids.include? wid
            if(current_user.form_submissions.all(:conditions=>['form_id = ? and ward_id = ?',self.id,wid]).present?)
              flag = false unless self.is_multi_submitable
            end
          end
        else
          flag = !current_user.form_submissions.all(:conditions=>{:form_id =>self.id}).present? unless self.is_multi_submitable
        end
      elsif(!self.is_feedback) ## feedback form
        if current_user.parent
          wid = current_user.guardian_entry.current_ward.user_id
          tids = self.net_targets(current_user)
          if(current_user.form_submissions.all(:conditions=>['form_id = ? and ward_id = ?',self.id,wid]).present?)
            flag = false unless (self.is_multi_submitable or tids.present?)
          end
        else
          flag = !current_user.form_submissions.all(:conditions=>{:form_id =>self.id}).present? unless (self.is_multi_submitable or tids.present?)
        end
      end
    end
    return flag
  end

  def allowed_to_edit? current_user
    flag = flag
    if(!self.is_closed)
      if(self.is_public)	## public form
        flag = (self.is_editable and (current_user.form_submissions.present? and current_user.form_submissions.all(:conditions=>{:form_id=>self.id}).present?)) ? true : false
      elsif(!self.is_public)	## private form
        uids = current_user.guardian_entry.wards.collect{|x| x.user_id} if current_user.parent
        uids = [current_user.id] if !current_user.parent

        if(self.is_editable)
          flag = ((self.viewer_ids & uids).present? and (current_user.form_submissions.present? and current_user.form_submissions.all(:conditions=>{:form_id=>self.id}).present?)) ? true : false
        else
          flag = false
        end

      elsif(self.is_feedback)	## feedback form
        flag = false
      end

    else ## give suitable error
      flag = false

    end
    return flag
  end

  def submitted? user
    if user.parent
      uid = user.guardian_entry.current_ward.user_id
      #      vids = self.viewer_ids
      result = user.form_submissions.all(:conditions=>['form_id = ? and ward_id = ? ',self.id,uid]).present?
    else
      result = (user.form_submissions.find_by_form_id(self.id) ? true : false)
    end
    return result
  end

  def permitted_to_submit? current_user
    #    return (current_user.admin ? true : (self.viewer_ids.include? current_user.id) ? true : false)
    if(self.is_closed)
      return false
    else
      if((self.viewer_ids.include? current_user.id) ? true : (self.is_public ? true : false))
        return (current_user.form_submissions.find_by_form_id(self.id) ? (self.is_multi_submitable ? true : false) : true)
      end
    end
  end

  def net_targets current_user
    #    p self.form_submissions.all(:select=>"target",:conditions=>{:user_id=>current_user}).map(&:target)
    if(self.is_targeted and current_user.parent)
      tids = self.form_target_ids
      vids = self.viewer_ids
      uids = [current_user.guardian_entry.current_ward.user_id]
      if(vids.include? uids.first)
        submitted_targets = current_user.form_submissions.all(:conditions => ['form_id = ? and ward_id = ?',self.id,uids.first]).map(&:target)
        return User.find_all_by_id(tids - submitted_targets)
      else
        return []
      end
    else
      User.find_all_by_id(self.form_target_ids - self.form_submissions.all(:select=>"target",:conditions=>{:user_id=>current_user}).map(&:target))
    end
  end

  def target_submited? current_user
    if self.is_targeted
      return self.form_submissions.find_all_by_target_id(current_user.id).count == 0 ? false : true
    else
      return false
    end
  end

  def permitted_to_update? current_user
    #    return (current_user.admin ? true : (self.viewer_ids.include? current_user.id) ? true : false)
    if(self.is_closed)
      return false
    else
      return (self.is_editable and ((self.viewer_ids.include? current_user.id) ? true : (self.is_public ? true : false)))
    end
  end

  def disabled?
    return (self.form_submissions.count > 0)? false : true
  end

  def can_edit_or_delete? current_user
    return (current_user.admin or current_user.privileges.map(&:name).include? 'FormBuilder')
  end

  def close
    if(self.is_closed)
      self.update_attribute(:is_closed,false)
      return 0
    else
      self.update_attribute(:is_closed,true)
      return 1
    end
  end
end
