class GenerateAttributeExamReport
  def initialize(param,agb_id)
    @agb = AssessmentGroupBatch.find agb_id
    @param=param
  end
  
  def fetch_report_data
    @score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @students = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    ass_marks = ConvertedAssessmentMark.find(:all,
      :conditions=>["assessment_group_batch_id= ?",@agb.id],
      :joins=>:assessment_group,
      :select=>'converted_assessment_marks.*,assessment_groups.maximum_marks')
    batch = Batch.find @param[:batch]
    batch.effective_students.each do |student|
      student_marks = ass_marks.to_a.select{|am| am.student_id == student.s_id}
      student_marks.each do |obj|
        @students[obj.markable_id][obj.student_id] = true
        if obj.actual_mark.present?
          obj.actual_mark.each_pair do |key,val|
            @score_hash[obj.markable_id][obj.student_id][key] = {:mark =>val[:mark],:grade =>val[:grade], :max_mark =>val[:max_mark] }
            @studentwise_score[obj.student_id][obj.markable_id][key] = {:mark =>val[:mark],:grade =>val[:grade] , :max_mark =>val[:max_mark]}
          end
        end
      end
    end
    @score_hash
  end
  
  def fetch_report_headers
    p @agb
    @header_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @agb.subject_attribute_assessments.each do |obj|
#      @header_hash[obj.subject_id] = {:attributes=>obj.assessment_attribute_profile.assessment_attributes.collect(&:name),:attribute_ids=>obj.assessment_attribute_profile.assessment_attributes.collect(&:id)}
      @header_hash[obj.subject_id] = obj.assessment_attribute_profile.assessment_attributes
    end
    @header_hash
  end
  
  def calculate_total
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        val.each_pair do |key,value|
          total_mark += value[:mark]
          max_total += value[:max_mark].to_i 
        end
        subjects_total[student_id] = {:total=> total_mark, :percentage => (total_mark*100)/max_total }
      end
    end
    subjects_total
  end
  
  def calculate_average
    avg = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @score_hash.each_pair do |sub_id,stud|
      attributes = []
      total_mark = {}
      stud.each_pair do |stud_id,val|
        val.each_pair do |key,value|
          total_mark[key] = total_mark[key] || []
          total_mark[key] << value[:mark] if value[:mark].present?
          attributes << key
        end
      end
      attributes.uniq.each do |attr| 
        avg[sub_id][attr] = total_mark[attr].sum / @students[sub_id].keys.count if total_mark[attr].present?
      end
    end
    avg
  end
  
  def find_highest
    highest = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @score_hash.each_pair do |sub_id,stud|
      attributes = []
      total_mark = {}
      stud.each_pair do |stud_id,val|
        val.each_pair do |key,value|
          total_mark[key] = total_mark[key] || []
          total_mark[key] << value[:mark] if value[:mark].present?
          attributes << key
        end
      end
      attributes.uniq.each do |attr| 
        highest[sub_id][attr] =  total_mark[attr].sort.last if total_mark[attr].present?
      end
    end
    highest
  end
  
  def find_rank
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    rank_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    arr = []
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        val.each_pair do |key,value|
          total_mark += value[:mark]
          max_total += value[:max_mark].to_i 
        end
      end
      subjects_total[student_id] =  (total_mark*100)/max_total 
    end
    subjects_total = subjects_total.sort_by {|_, value| value}.reverse
        total = subjects_total.map{|x| x.last}
    sorted = total.sort.uniq.reverse
    rank = total.map{|e| sorted.index(e) + 1}
    rank.each_with_index do |r,i|
      arr<<[subjects_total[i].first,r]
    end
    arr.each do |obj|
      rank_hash[obj.first] = {:rank=>obj.last}
    end
    rank_hash
  end
  
end