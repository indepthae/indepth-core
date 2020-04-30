update_flag = Configuration.find_by_config_key("ModifyingOnlineExam")
if update_flag.nil?
  update_flag = Configuration.create(:config_key=>"ModifyingOnlineExam",:config_value=>"1")
else
  update_flag.update_attributes(:config_value=>"1")
end


OnlineExamGroup.send :belongs_to, :old_batch, :class_name=>'Batch', :foreign_key=>:batch_id
OnlineExamGroup.send :has_many, :old_online_exam_questions, :class_name=>'OnlineExamQuestion'

batch_inserts = []
student_inserts = []
question_inserts = []
batch_count = 0
student_count = 0
question_count = 0
ms = MultiSchool rescue nil
question_query = unless(ms)
  "INSERT INTO online_exam_groups_questions (`online_exam_group_id` ,`online_exam_question_id`,`mark`,`answer_ids`,`position`,`created_at`,`updated_at`)"
else
  "INSERT INTO online_exam_groups_questions (`online_exam_group_id` ,`online_exam_question_id`,`mark`,`answer_ids`,`position`,`created_at`,`updated_at`,`school_id`)"
end

exam_groups = OnlineExamGroup.all(:include=>[:students,{:old_batch=>:students},{:online_exam_attendances=>:student},{:old_online_exam_questions=>:online_exam_options}])

exam_groups.each do|exam_group|
  students = []
  unless exam_group.old_batch.nil?
    batch = exam_group.old_batch
    if exam_group.batches.empty?
      batch_inserts << "(#{exam_group.id}, #{batch.id})"
      batch_count = batch_count + 1
      if (batch_count >= 1000)
        batchinsertsql = "INSERT INTO online_exam_groups_batches (`online_exam_group_id` ,`batch_id`) VALUES #{batch_inserts.join(', ')} ;"
          RecordUpdate.connection.execute(batchinsertsql)
          batch_count=0
          batch_inserts=[]
      end
    end
    students = batch.students
  end
  attended_students = exam_group.online_exam_attendances.collect(&:student).compact
  students = students + attended_students
  if exam_group.students.empty?
    unique_students = students.uniq
    unique_students.each do|student|
      student_inserts << "(#{exam_group.id}, #{student.id})"
      student_count = student_count + 1
      if (student_count >= 1000)
        studentinsertsql = "INSERT INTO online_exam_groups_students (`online_exam_group_id` ,`student_id`) VALUES #{student_inserts.join(', ')} ;"
          RecordUpdate.connection.execute(studentinsertsql)
          student_count=0
          student_inserts=[]
      end
    end
  end

  exam_questions = exam_group.old_online_exam_questions
  unless exam_questions.empty?
    prev_question_last = OnlineExamGroupsQuestion.last(:conditions=>{:online_exam_group_id=>exam_group.id},:order=>"position ASC")
    last_position = prev_question_last ? (prev_question_last.position || 0) : 0
    exam_questions.each do|question|
      exam_option_ids = question.online_exam_options.collect(&:id)
      question_inserts << "(#{exam_group.id}, #{question.id}, #{question.mark}, '#{YAML.dump(exam_option_ids)}', #{last_position+1}, '#{question.created_at.strftime("%Y-%m-%d %H:%M:%S")}', '#{question.updated_at.strftime("%Y-%m-%d %H:%M:%S")}'#{(', '+ms.current_school.id.to_s) if ms})"
      last_position=last_position+1
      question_count = question_count + 1
      if (question_count >= 1000)
        questioninsertsql = "#{question_query} VALUES #{question_inserts.join(', ')} ;"
          RecordUpdate.connection.execute(questioninsertsql)
          question_count=0
          question_inserts=[]
      end
    end
    exam_group.old_online_exam_questions.update_all(:question_format=>"objective")
  end
  unless exam_group.exam_format=="hybrid"
    exam_group.online_exam_attendances.update_all(:answers_evaluated=>true)
  end

  if exam_group == exam_groups.last
    unless batch_inserts.empty?
      batchinsertsql = "INSERT INTO online_exam_groups_batches (`online_exam_group_id` ,`batch_id`) VALUES #{batch_inserts.join(', ')} ;"
        RecordUpdate.connection.execute(batchinsertsql)
        batch_count=0
        batch_inserts=[]
    end
    unless student_inserts.empty?
      studentinsertsql = "INSERT INTO online_exam_groups_students (`online_exam_group_id` ,`student_id`) VALUES #{student_inserts.join(', ')} ;"
        RecordUpdate.connection.execute(studentinsertsql)
        student_count=0
        student_inserts=[]
    end
    unless question_inserts.empty?
      questioninsertsql = "#{question_query} VALUES #{question_inserts.join(', ')} ;"
        RecordUpdate.connection.execute(questioninsertsql)
        question_count=0
        question_inserts=[]
    end
  end
end

OnlineExamGroup.update_all({:exam_type=>"general",:exam_format=>"objective",:result_published=>true},["(exam_format is null) and is_published = 1"])
OnlineExamGroup.update_all({:exam_type=>"general",:exam_format=>"objective",:result_published=>false},["(exam_format is null) and is_published = 0"])

update_flag.update_attributes(:config_value=>"0")