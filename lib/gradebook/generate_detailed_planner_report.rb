class GenerateDetailedPlannerReport
  
  attr_accessor :exam_max_marks,:fetch_report_headers,:over_marks
  
  def initialize(param)
    @plan = AssessmentPlan.find param[:exam].split('_').last
    @param = param
    @batch = Batch.find @param[:batch]
    #@assessment_group = @batch.assessment_groups.first(:conditions=>{:parent_id=>@plan.id,:parent_type=>"AssessmentPlan", :is_final_term=>true}).assessment_groups
    @assessment_terms = @plan.assessment_terms.all(:include => :assessment_groups)
    load_report_headers
  end
  
  def fetch_report_data
    @exam_max_marks =  Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    overrided_marks = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @students = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    students = @batch.effective_students
    subject_codes = @batch.subjects.collect(&:code)
    @assessment_terms.each do |at|
      
      agroups = @batch.assessment_groups.first(:conditions=>{:parent_id=>at.id,:parent_type=>"AssessmentTerm", :is_final_term=>true})
      if agroups.present?
        assessment_groups = agroups.assessment_groups
      else
        assessment_groups = @batch.assessment_groups.all(:conditions=>{:parent_id=>at.id,:parent_type=>"AssessmentTerm"})
      end
      
      if assessment_groups.present?
        assessment_groups.each do |ag|
          overrided_marks[at.id][ag.id] = ag.override_assessment_marks.find(:all,
            :joins=>"INNER JOIN courses on courses.id = override_assessment_marks.course_id INNER JOIN batches on batches.course_id = courses.id INNER JOIN subjects ON subjects.name = override_assessment_marks.subject_name AND subjects.school_id = #{MultiSchool.current_school.id} AND subjects.batch_id = #{@batch.id}",
            :select=>'override_assessment_marks.*,subjects.id subject_id',
            :conditions=>["subject_code in (?)",subject_codes]).group_by(&:subject_id)
          @agb = ag.assessment_group_batches.to_a.find{|agb| agb.batch_id == @param[:batch].to_i}
          next if @agb.nil?
          ass_marks = @agb.converted_assessment_marks
          students.each do |student|
            student_marks = ass_marks.to_a.select{|am| am.student_id == student.s_id}
        
            student_marks.each do |obj|
              @students[obj.markable_id][at.id][ag.id][obj.student_id] = true
              if (@param[:type] == "planner" or ag.type == "DerivedAssessmentGroup" or !ag.is_single_mark_entry) and @param[:type] != "percent"
                maximum_marks = (overrided_marks[at.id][ag.id][obj.markable_id.to_s].present? ? overrided_marks[at.id][ag.id][obj.markable_id.to_s].first.maximum_marks.to_f : ag.maximum_marks)
                @exam_max_marks[at.id][obj.markable_id][ag.id] = ag.maximum_marks
                if ag.scoring_type == 1
                  @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark =>obj.grade.present? ? obj.grade : (obj.mark.present? ? obj.mark.to_f : "-") ,:actual=>obj.mark.to_f}
                elsif ag.scoring_type == 2
                  @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark=>obj.grade || "-",:actual=>nil} 
                else
                  @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark => obj.grade.present? ? (obj.mark.present? ? "#{obj.mark.to_f}(#{obj.grade})" : "(#{obj.grade})") : (obj.mark.present? ? "#{obj.mark.to_f}" : "-") ,:actual=>obj.mark.to_f}
                end
                @studentwise_score[obj.student_id][obj.markable_id][at.id][ag.id] = {:mark => obj.mark.to_f, :max_mark => maximum_marks}
              elsif @param[:type] == "exam"  
                max_mark = obj.assessment_group_batch.subject_assessments.to_a.find{|sa| sa.subject_id == obj.markable_id}.try(:maximum_marks).to_f
                @exam_max_marks[at.id][obj.markable_id][ag.id] = max_mark
                if obj.actual_mark.present?
                  case ag.scoring_type
                  when 1
                    @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark=> (obj.actual_mark[:grade].present? ? obj.actual_mark[:grade] : (obj.actual_mark[:mark].present? ? obj.actual_mark[:mark] : "-") ),:actual=>obj.actual_mark[:mark]}
                  when 2
                    @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark =>obj.actual_mark[:grade] || "-",:actual=>nil}
                  when 3
                    @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark=>"#{obj.actual_mark[:mark]}(#{obj.actual_mark[:grade]})",:actual=>obj.actual_mark[:mark]}
                  end
                end
                @studentwise_score[obj.student_id][obj.markable_id][at.id][ag.id] = {:mark => obj.mark.to_f, :max_mark => max_mark}
              elsif @param[:type] == "percent"
                maximum_marks = (overrided_marks[at.id][ag.id][obj.markable_id.to_s].present? ? overrided_marks[at.id][ag.id][obj.markable_id.to_s].first.maximum_marks.to_f : ag.maximum_marks)
                @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark=>obj.mark.present? ? "#{((obj.mark.to_f*100)/maximum_marks).round(2)}%" : "-", :actual=>(obj.mark.to_f*100)/maximum_marks} if [1,3].include? ag.scoring_type
                @score_hash[obj.markable_id][obj.student_id][at.id][ag.id] = {:mark=>obj.grade || "-",:actual=>nil} if ag.scoring_type == 2
                @studentwise_score[obj.student_id][obj.markable_id][at.id][ag.id] = {:mark => obj.mark.to_f, :max_mark => maximum_marks}
              end
            end
          end
        end
      end
    end
    @score_hash
  end
  
  def load_report_headers
    @ags = {}
    @over_marks = {}
    @fetch_report_headers = {}
    @header_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @assessment_terms.each do |at|
      agroups = @batch.assessment_groups.first(:conditions=>{:parent_id=>at.id,:parent_type=>"AssessmentTerm", :is_final_term=>true})
      if agroups.present?
        agbs = agroups.assessment_groups.collect(&:id)
      else
        agbs = @batch.assessment_groups.all(:conditions=>{:parent_id=>at.id,:parent_type=>"AssessmentTerm"}).collect(&:id)
      end
        @ags[at.id] = ConvertedAssessmentMark.all(
          :conditions=>["assessment_group_id in (?) and assessment_groups.parent_id = ?",agbs,at.id],
          :joins=>[:assessment_group],
          :select=>"markable_id s_id,assessment_groups.name ag_name,assessment_groups.id ag_id,assessment_groups.maximum_marks max_mark,assessment_groups.is_single_mark_entry,assessment_groups.type ag_type,assessment_groups.scoring_type scoring_type",
          :group=>['s_id,ag_id'])
        @over_marks[at.id] = OverrideAssessmentMark.all(:conditions => {:course_id => @batch.course_id, :assessment_group_id => agbs}).group_by(&:assessment_group_id)
        @fetch_report_headers[at.id] = @ags[at.id].group_by(&:s_id)
      
    end
    @fetch_report_headers
  end
  
  def get_column_span_count
    span_count = []
    @assessment_terms.each do |at|
      span_count[at.id] = 0
      @header_hash[at.id].keys.each do |s_id|
        span_count[at.id] += @header_hash[at.id][s_id.to_s].count
      end
    end
    span_count
  end
  
  def calculate_total
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        val.each_pair do |key,at|
          at.each_pair do |_,ag|
            total_mark += ag[:mark].to_f
            max_total += ag[:max_mark].to_f
          end
        end
        subjects_total[student_id] = {:total=> total_mark, :percentage => (total_mark*100)/max_total }
      end
    end
    subjects_total
  end
  
  def find_rank
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    rank_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    total = []
    arr = []
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        val.each_pair do |key,at|
          at.each_pair do |_,ag|
            total_mark += ag[:mark]
            max_total += ag[:max_mark].to_f 
          end
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
      rank_hash[obj.first]={:rank=>obj.last}
    end
    rank_hash
  end
  
  def calculate_average
    avg = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    total_mark = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    terms = []
    assessment_groups = []
    @score_hash.each_pair do |sub_id,stud|
      stud.each_pair do |stud_id,at|
        at.each_pair do |at_id,ag|
          ag.each_pair do |ag_id,value|
            total_mark[sub_id][at_id][ag_id] = total_mark[sub_id][at_id][ag_id].present? ? total_mark[sub_id][at_id][ag_id] : []
            total_mark[sub_id][at_id][ag_id] << (value[:actual].present? ? value[:actual] : nil)
            assessment_groups << ag_id
          end
          terms << at_id
        end
      end
      terms.uniq.each do |at|
        assessment_groups.uniq.each do |eg| 
          total_mark[sub_id][at][eg].each do |value|
            avg[sub_id][at][eg] = total_mark[sub_id][at][eg].compact.sum / @students[sub_id][at][eg].keys.count unless (value.nil? or total_mark[sub_id][at][eg].nil?)
          end
        end
      end
    end
    avg
  end
  
  def find_highest
    avg = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    total_mark = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    terms = []
    assessment_groups = []
    @score_hash.each_pair do |sub_id,stud|
      stud.each_pair do |stud_id,at|
        at.each_pair do |at_id,ag|
          ag.each_pair do |ag_id,value|
            total_mark[sub_id][at_id][ag_id] = total_mark[sub_id][at_id][ag_id].present? ? total_mark[sub_id][at_id][ag_id] : []
            total_mark[sub_id][at_id][ag_id] << (value[:actual].present? ? value[:actual] : nil)
            assessment_groups << ag_id
          end
          terms << at_id
        end
      end
      terms.uniq.each do |at|
        assessment_groups.uniq.each do |eg| 
          next unless total_mark[sub_id][at][eg].present?
          avg[sub_id][at][eg] = total_mark[sub_id][at][eg].compact.sort.last 
        end
      end
    end
    avg
  end
  
end