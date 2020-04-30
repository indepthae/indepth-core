class GenerateDetailedTermReport
  
  attr_accessor :over_marks, :fetch_report_headers
  attr_accessor :exam_max_marks
  
  def initialize(param)
    @term = AssessmentTerm.find param[:exam].split('_').last
    @param = param
    @batch = Batch.find @param[:batch]
    load_header_data
  end
  
  def fetch_report_data
    @exam_max_marks =  Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @mark_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @students = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    overrided_marks = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    assessment_groups = @term.assessment_groups
    assessment_group_batches = AssessmentGroupBatch.all(:include=>:converted_assessment_marks,:conditions=>["batch_id=? and assessment_group_id in (?)",@batch.id,assessment_groups.collect(&:id)])
    subject_codes = @batch.subjects.collect(&:code)
    assessment_groups.each do |ag|
      overrided_marks[ag.id] = ag.override_assessment_marks.find(:all,
        :joins=>"INNER JOIN courses on courses.id = override_assessment_marks.course_id INNER JOIN batches on batches.course_id = courses.id INNER JOIN subjects ON subjects.name = override_assessment_marks.subject_name AND subjects.school_id = #{MultiSchool.current_school.id} AND subjects.batch_id = #{@batch.id}",
        :select=>'override_assessment_marks.*,subjects.id subject_id',
        :conditions=>["subject_code in (?)",subject_codes]).group_by(&:subject_id)
      @agb = assessment_group_batches.to_a.find{|agb| agb.assessment_group_id == ag.id }
      next if @agb.nil?
      ass_marks = @agb.converted_assessment_marks
      @batch.effective_students.each do |student|
        student_marks = ass_marks.to_a.select{|am| am.student_id == student.s_id}
        student_marks.each do |obj|
          @students[obj.markable_id][ag.id][obj.student_id] = true
          if (@param[:type] == "planner" or ag.type == "DerivedAssessmentGroup" or !ag.is_single_mark_entry) and @param[:type] != "percent"
            maximum_marks = (overrided_marks[ag.id][obj.markable_id.to_s].present? ? overrided_marks[ag.id][obj.markable_id.to_s].first.maximum_marks.to_f : ag.maximum_marks)
            @exam_max_marks[obj.markable_id][ag.id] = ag.maximum_marks
            if ag.scoring_type == 1
              @mark_hash[obj.markable_id][obj.student_id][ag.id][:mark] = obj.grade.present? ? obj.grade : obj.mark.to_f
              @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.grade.present? ? obj.grade : obj.mark.to_f
              @studentwise_score[obj.student_id][obj.markable_id][ag.id] = {:mark => obj.grade.present? ? obj.grade : obj.mark.to_f, :max_mark => maximum_marks}
#              @studentwise_score[obj.student_id][obj.markable_id][ag.id][:max_mark] = @over_marks[ag.id] if @over_marks[ag.id].present?
            elsif ag.scoring_type == 2
              @mark_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.mark.to_f
              @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.grade 
            else
              @mark_hash[obj.markable_id][obj.student_id][ag.id][:mark] = obj.grade.present? ? (obj.mark.present? ? "#{obj.mark.to_f} (#{obj.grade})" : "#{obj.grade}") : obj.mark.to_f
              @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.grade.present? ? (obj.mark.present? ? "#{obj.mark.to_f} (#{obj.grade})" : "#{obj.grade}") : obj.mark.to_f
              @studentwise_score[obj.student_id][obj.markable_id][ag.id] = {:mark=>obj.grade.present? ? (obj.mark.present? ? "#{obj.mark.to_f} (#{obj.grade})" : "#{obj.grade}") : obj.mark.to_f , :max_mark => maximum_marks}
#              @studentwise_score[obj.student_id][obj.markable_id][ag.id] = {:mark=>obj.mark.present? ? obj.mark.to_f : nil, :max_mark => @over_marks[ag.id]} if @over_marks[ag.id].present?
            end
          elsif @param[:type] == "exam"
            max_mark = obj.assessment_group_batch.subject_assessments.to_a.find{|sa| sa.subject_id == obj.markable_id}.try(:maximum_marks).to_f
            @exam_max_marks[obj.markable_id][ag.id] = max_mark
            if obj.actual_mark.present?
              case ag.scoring_type
              when 1
                @mark_hash[obj.markable_id][obj.student_id][ag.id] = {:mark =>obj.actual_mark[:grade].present? ? obj.actual_mark[:grade] : obj.actual_mark[:mark], :max_mark=>max_mark}
                @score_hash[ag.id][obj.markable_id][obj.student_id] = {:mark=>obj.actual_mark[:grade].present? ? obj.actual_mark[:grade] : obj.actual_mark[:mark], :max_mark=>max_mark}
                @studentwise_score[obj.student_id][obj.markable_id][ag.id] = {:mark => obj.actual_mark[:grade].present? ? obj.actual_mark[:grade] : obj.actual_mark[:mark], :max_mark=>max_mark }
              when 2
                @studentwise_score[obj.student_id][obj.markable_id][ag.id] = {:mark => obj.actual_mark[:mark], :max_mark=>max_mark }
                @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.actual_mark[:grade]
              when 3
                @mark_hash[obj.markable_id][obj.student_id][ag.id][:mark] = obj.actual_mark[:mark]
                @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = "#{obj.actual_mark[:mark]}(#{obj.actual_mark[:grade]})"
                @studentwise_score[obj.student_id][obj.markable_id][ag.id] = { :mark=>obj.actual_mark[:mark], :grade=>obj.actual_mark[:grade], :max_mark=>max_mark }
              end
            end
          elsif @param[:type] == "percent"
            maximum_marks = (overrided_marks[ag.id][obj.markable_id.to_s].present? ? overrided_marks[ag.id][obj.markable_id.to_s].first.maximum_marks.to_f : ag.maximum_marks)
            @mark_hash[obj.markable_id][obj.student_id][ag.id] = {:mark => (obj.mark.to_f*100)/maximum_marks } if [1,3].include? ag.scoring_type
            @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.mark.present? ? "#{((obj.mark.to_f*100)/maximum_marks).round(2)}%" : "-" if [1,3].include? ag.scoring_type
            @studentwise_score[obj.student_id][obj.markable_id][ag.id][:mark] = (obj.mark.to_f*100)/maximum_marks if [1,3].include? ag.scoring_type
            @score_hash[ag.id][obj.markable_id][obj.student_id][:mark] = obj.grade || "-" if ag.scoring_type == 2
          end
        end
      end
    end
    
    @score_hash
  end
  
  def load_header_data # fetch_report_headers
    agbs = @batch.assessment_group_batches.collect(&:id)
    @ags = ConvertedAssessmentMark.all(
      :conditions=>["assessment_group_batch_id in (?) and assessment_groups.parent_id = ?",agbs,@term.id],
      :joins=>[:assessment_group],
      :select=>"markable_id s_id,assessment_groups.name ag_name,assessment_groups.type ag_type,assessment_groups.is_single_mark_entry,assessment_groups.id ag_id,assessment_groups.maximum_marks max_mark, assessment_groups.scoring_type scoring_type",
      :group=>['s_id,ag_id'])
    @over_marks = OverrideAssessmentMark.all(:conditions => {:course_id => @batch.course_id, :assessment_group_id => @ags.collect(&:ag_id)}).group_by(&:assessment_group_id)
    @fetch_report_headers = @ags.group_by(&:s_id)
    
  end
  
  def calculate_total
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        val.each_pair do |key,value|
          total_mark += value[:mark].to_f if value[:mark].present?
          max_total += value[:max_mark].to_f if value[:max_mark].present?
        end
        subjects_total[student_id] = {:total=> total_mark, :percentage => (max_total.zero? ? nil : (total_mark*100)/max_total) }
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
        val.each_pair do |key,value|
          total_mark += value[:mark].to_f if value[:mark].present?
          max_total += value[:max_mark].to_f if value[:max_mark].present?
        end
      end
      subjects_total[student_id] = (total_mark*100)/max_total unless max_total.zero?
    end
    if subjects_total.present?
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
    end
    rank_hash
  end
  
  def calculate_average
    avg = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @mark_hash.each_pair do |sub_id,stud|
      exam_groups = []
      total_mark = {}
      stud.each_pair do |stud_id,val|
        val.each_pair do |key,value|
          total_mark[key] = total_mark[key].present? ? total_mark[key] : []
          total_mark[key] << value[:mark]
          exam_groups << key
        end
      end
      exam_groups.uniq.each do |eg| 
        avg[sub_id][eg] = total_mark[eg].map(&:to_f).sum / @students[sub_id][eg].keys.count if total_mark[eg].present?
      end
    end
    avg
  end
  
  def find_highest
    highest = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @mark_hash.each_pair do |sub_id,stud|
      exam_groups = []
      total_mark = {}
      stud.each_pair do |stud_id,val|
        val.each_pair do |key,value|
          total_mark[key] = total_mark[key] || []
          total_mark[key] << value[:mark]
          exam_groups << key
        end
      end
      exam_groups.uniq.each do |eg| 
        highest[sub_id][eg] = total_mark[eg].sort.last
      end
    end
    highest
  end
  
end