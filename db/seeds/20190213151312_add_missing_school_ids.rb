{:GradebookRecordGroup => :AssessmentPlan,:GradebookRecord => :RecordGroup,:GradebookRemark => :Batch ,:RemarkSet => :AssessmentPlan}.each do |prb, svr|

  prb_klass = prb.to_s.constantize
  svr_klass =  svr.to_s.constantize
  svr_assoc = svr.to_s.underscore + '_id'

  records = prb_klass.all(:skip_multischool=>true, :conditions => {:school_id => nil})
  records = records.group_by{|x| x.send(svr_assoc)}

  school_id_maps = {}
  svr_klass.all(:select => "id, school_id", :skip_multischool=>true, :conditions => {:id => records.keys}).each{|x| school_id_maps[x.id] = x.school_id }

  queries = []
  records.each do |key, vals|
    vals.each do |row|
      queries << "update #{prb_klass.table_name} set school_id = #{school_id_maps[key]} where id = #{row.id} ;"
    end
  end
  
  queries.each {|x| ActiveRecord::Base.connection.execute(x); }
end