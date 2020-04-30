class GenerateSubjectExamReport
  attr_accessor :headers
  def initialize(param,agb_id,maximum_marks)
    @param = param
    @agb_id = agb_id
    @maximum_marks = maximum_marks
  end
  
  def fetch_report_data
    @score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @students =  Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    ass_marks = ConvertedAssessmentMark.find(:all,
      :conditions=>["assessment_group_batch_id= ?",@agb_id],
      :joins=>:assessment_group,
      :select=>'converted_assessment_marks.*,assessment_groups.maximum_marks', 
      :include => {:assessment_group_batch=>:subject_assessments})
    batch = Batch.find @param[:batch]
    subject_codes = batch.subjects.collect(&:code)
    assessment_group = AssessmentGroup.find @param[:exam].split('_').last.to_i
    overrided_marks = assessment_group.override_assessment_marks.find(:all,
      :joins=>"INNER JOIN courses on courses.id = override_assessment_marks.course_id INNER JOIN batches on batches.course_id = courses.id INNER JOIN subjects ON subjects.name = override_assessment_marks.subject_name AND subjects.school_id = #{MultiSchool.current_school.id} AND subjects.batch_id = #{batch.id}",
      :select=>'override_assessment_marks.*,subjects.id subject_id',
      :conditions=>["subject_code in (?) and override_assessment_marks.course_id = ? ",subject_codes, batch.course_id]).group_by(&:subject_id)
    batch.effective_students.each do |student|
      student_marks = ass_marks.to_a.select{|am| am.student_id == student.s_id}
      student_marks.each do |obj|
        @students[obj.markable_id][obj.student_id] = true
        if @param[:type] == "exam"
          max_mark = obj.assessment_group_batch.subject_assessments.to_a.find{|sa| sa.subject_id == obj.markable_id}.try(:maximum_marks).to_f
          if obj.actual_mark.present?
            @studentwise_score[obj.student_id][obj.markable_id] = {:mark=>obj.actual_mark[:mark], :grade=>obj.actual_mark[:grade], :max_mark=>max_mark }
            @score_hash[obj.markable_id][obj.student_id] = {:mark=>obj.actual_mark[:mark], :grade=>obj.actual_mark[:grade], :max_mark=>max_mark}
          end
          @studentwise_score[obj.student_id][obj.markable_id][:max_mark] = max_mark
        elsif @param[:type] == "planner"
          @studentwise_score[obj.student_id][obj.markable_id] = {:mark =>(obj.mark.present? ? obj.mark.to_f : obj.mark),:grade =>obj.grade, :max_mark=>(overrided_marks[obj.markable_id.to_s].present? ? overrided_marks[obj.markable_id.to_s].first.maximum_marks.to_f : obj.maximum_marks.to_f)}
          @score_hash[obj.markable_id][obj.student_id] = {:mark =>(obj.mark.present? ? obj.mark.to_f : obj.mark),:grade =>obj.grade, :max_mark=>obj.maximum_marks } if obj.actual_mark.present?
        elsif @param[:type] == "obtained_grade"
          @score_hash[obj.markable_id][obj.student_id] = {:grade =>obj.grade }
          @studentwise_score[obj.student_id][obj.markable_id] = {:grade =>obj.grade }
        elsif @param[:type] == "percent" and obj.mark.present?
          maximum_marks = (overrided_marks[obj.markable_id.to_s].present? ? overrided_marks[obj.markable_id.to_s].first.maximum_marks.to_f : obj.maximum_marks.to_f)
          percentage = (obj.mark.to_f*100)/maximum_marks# if obj.mark.present?
          @score_hash[obj.markable_id][obj.student_id] = {:mark =>percentage.round(2)}
          @studentwise_score[obj.student_id][obj.markable_id] = {:mark =>percentage}
        end
      end

    end
    @headers = {}
    SubjectAssessment.all(:conditions => {:assessment_group_batch_id => @agb_id}).each do |sa|
      @headers[sa.subject_id] = sa.maximum_marks
    end
    @score_hash
  end
  
  def calculate_total
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        total_mark += val[:mark] if val[:mark].present?
        max_total += val[:max_mark] if val[:max_mark].present?
      end
      subjects_total[student_id] = {:total=> total_mark, :percentage => (total_mark*100)/max_total }
    end
    subjects_total
  end
  
  def calculate_average
    avg = {}
    @score_hash.each_pair do |sub_id,stud|
      total_mark = 0
      stud.each_pair do |stud_id,val|
        total_mark += val[:mark] if val[:mark].present?
      end
      avg[sub_id] = total_mark/(@students[sub_id].keys.count) if @students[sub_id].keys.count != 0
    end
    avg
  end
  
  def find_highest
    highest = {}
    @score_hash.each_pair do |sub_id,stud|
      highest[sub_id] = 0
      stud.each_pair do |stud_id,val|
        if val[:mark].present? and highest[sub_id] <= val[:mark]
          highest[sub_id] = val[:mark]
        end
      end
    end
    highest
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
        total_mark += val[:mark] if val[:mark].present?
        max_total += val[:max_mark].to_i
      end
      subjects_total[student_id] =  (total_mark*100)/max_total
    end
    subjects_total = subjects_total.sort_by {|_key, value| value}.reverse
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
  
end