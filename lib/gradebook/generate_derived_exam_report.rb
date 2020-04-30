class GenerateDerivedExamReport
  def initialize(param,agb_id)
    @param = param
    @agb_id = agb_id
  end
  
  def fetch_report_data
    @score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @students = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    ass_marks = ConvertedAssessmentMark.find(:all,
      :conditions=>["assessment_group_batch_id= ?",@agb_id],
      :joins=>:assessment_group,
      :select=>'converted_assessment_marks.*,assessment_groups.maximum_marks')
    batch = Batch.find @param[:batch]
    batch.effective_students.each do |student|
      student_marks = ass_marks.to_a.select{|am| am.student_id == student.s_id}
      student_marks.each do |obj|
        @students[obj.markable_id][obj.student_id] = true
        @score_hash[obj.markable_id][obj.student_id] = {:mark =>obj.mark.to_f,:grade =>obj.grade}
        @studentwise_score[obj.student_id][obj.markable_id] = {:mark =>obj.mark.to_f,:grade =>obj.grade,:max_mark=>obj.maximum_marks }
      end
    end
    @score_hash
  end
  
  def calculate_total
    subjects_total = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        total_mark += val[:mark]
        max_total += val[:max_mark].to_f 
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
      avg[sub_id] = total_mark/(@students[sub_id].keys.count) if @students[sub_id].keys.count 
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
    arr = []
    @studentwise_score.each_pair do |student_id,subject|
      total_mark = 0
      max_total = 0
      subject.each_pair do |subject_id,val|
        total_mark += val[:mark]
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
