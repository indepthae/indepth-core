FeatureLock::run_with_feature_lock :cce_enhancement do
  inserts=[]
  if (MultiSchool rescue false)
    School.active.each do |s|
      MultiSchool.current_school = s
      CceReport.all(
        :select=>"cce_reports.*,exams.subject_id,fa_criterias.fa_group_id fg_id,fa_criterias.max_marks fc_max,fa_groups.criteria_formula as c_formula,fa_criterias.formula_key as c_key,fa_groups.max_marks fg_max",
        :joins=>"INNER JOIN `fa_criterias` ON `fa_criterias`.id = `cce_reports`.observable_id AND `cce_reports`.observable_type = 'FaCriteria' AND fa_criterias.is_deleted = false INNER JOIN `fa_groups` ON `fa_groups`.id = `fa_criterias`.fa_group_id INNER JOIN `exams` ON `exams`.id = `cce_reports`.exam_id").group_by(&:batch_id).each do |batch_id,reports|
        batch=Batch.find(batch_id)
        grades=batch.grading_level_list
        reports.group_by(&:student_id).each do |k,v|
          v.group_by(&:exam_id).each do |e_id,e_val|
            e_val.group_by(&:fg_id).each do |fag_id,fag_val|
              fg_formula=fag_val[0].c_formula.present? ? fag_val[0].c_formula : "avg(#{FaGroup.find_by_id(fag_id).fa_criterias.active.collect(&:formula_key).join(',')},@#{fag_val.collect(&:fg_max).uniq.first})"
              fa_obtained_score_hash={}
              fag_val.group_by(&:c_key).each do |indicator,mark|
                hsh1={indicator=>((mark[0].grade_string.to_f/100)*mark[0].fc_max.to_f)}
                fa_obtained_score_hash.merge!hsh1
              end
              fa_max_score_hash={}
              fag_val.group_by(&:c_key).each do |indicator,mark|
                hsh1={indicator=>mark[0].fc_max.to_f}
                fa_max_score_hash.merge!hsh1
              end
              equation = ExamFormula.new(fg_formula,:obtained_marks=>fa_obtained_score_hash,:max_marks=>fa_max_score_hash,:mode=>:tmm,:sum=>true)
              if equation.valid?
                result = equation.calculate
                fa_group=FaGroup.find_by_id(fag_id)
                converted_mark=result.into(100)
                obtained_mark=result.into(fag_val.collect(&:fg_max).first.to_f)
                grade_string = grades.to_a.find{|g| g.min_score <= converted_mark.to_f.round(2).round}.try(:name) || "" if /^[\d]+(\.[\d]+){0,1}$/ === converted_mark.to_s
                inserts.push "(#{fa_group.id},'FaGroup',#{s.id},#{k},'#{grade_string}',#{e_id},#{batch_id},#{obtained_mark.to_f},#{converted_mark.to_f},#{fag_val.collect(&:fg_max).first.to_f},'#{DateTime.now.strftime('%F %T')}','#{DateTime.now.strftime('%F %T')}')"
              else
                fa_group=FaGroup.find_by_id(fag_id)
                converted_mark = obtained_mark = 0.0
                grade_string = grades.to_a.find{|g| g.min_score <= converted_mark.to_f.round(2).round}.try(:name) || "" if /^[\d]+(\.[\d]+){0,1}$/ === converted_mark.to_s
                inserts.push "(#{fa_group.id},'FaGroup',#{s.id},#{k},'#{grade_string}',#{e_id},#{batch_id},#{obtained_mark.to_f},#{converted_mark.to_f},#{fag_val.collect(&:fg_max).first.to_f},'#{DateTime.now.strftime('%F %T')}','#{DateTime.now.strftime('%F %T')}')"
              end
            end
          end
        end
        batch.delete_student_cce_report_cache
      end
    end
    unless inserts.blank?
      inserts.each_slice(1000).each do |slice|
        sql = "INSERT INTO cce_reports (observable_id,observable_type,school_id,student_id,grade_string,exam_id,batch_id,obtained_mark,converted_mark,max_mark,created_at,updated_at) VALUES #{slice.join(", ")}"
        ActiveRecord::Base.connection.execute(sql)
      end
    end
    CceReport.delete_all({:observable_type=>'FaCriteria'})
  end
end
