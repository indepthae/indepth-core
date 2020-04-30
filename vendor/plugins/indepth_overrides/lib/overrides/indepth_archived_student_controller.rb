module IndepthOverrides
  module IndepthArchivedStudentController
  	def self.included (base)
      base.instance_eval do
        alias_method_chain :revert_archived_student, :tmpl
      end
    end
    
    def revert_archived_student_with_tmpl
      as=ArchivedStudent.find(params[:id]).former_id
      student=ArchivedStudent.archived_student_revert(params[:id])
      if student.nil?
        flash[:notice]=t('cannot_revert')
        redirect_to :controller=>'archived_student',:action=>"profile",:id=>params[:id]
      elsif student.present?
        flash[:notice]=t('successfully_reverted')
        redirect_to :controller=>'student',:action=>"profile",:id=>as
      elsif student.errors.present?
        flash[:notice]=student.errors.full_messages.first
        redirect_to :controller=>'archived_student',:action=>"profile",:id=>params[:id]
      end
    end
    
  end
end