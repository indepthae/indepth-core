# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module EffectiveStudents
  def effective_students
    if @batch.is_active?
      @batch.students.all(:order => Student.sort_order)
    else
      sql = <<-SQL
       select s.id id,CONCAT_WS('',s.first_name,' ',s.last_name) full_name,s.admission_no,s.first_name,s.last_name,
        bs.roll_number roll_number from students s inner join batch_students bs on bs.student_id=s.id where bs.batch_id=#{@batch.id} UNION ALL select ars.former_id id,
        CONCAT_WS('',ars.first_name,' ',ars.last_name) full_name,ars.admission_no,ars.first_name,ars.last_name,ars.roll_number roll_number from archived_students ars where ars.batch_id=#{@batch.id}
        UNION ALL select ars1.former_id id,CONCAT_WS('',ars1.first_name,' ',ars1.last_name) full_name,ars1.admission_no,ars1.first_name,ars1.last_name,
        bs.roll_number roll_number from archived_students ars1 inner join batch_students bs on bs.student_id=ars1.former_id where bs.batch_id=#{@batch.id}  order by #{Student.sort_order}

      SQL
      
      BatchStudent.find_by_sql(sql)
#      Student.all(:joins => :batch_students, :conditions=>{:batch_students =>{:batch_id => @batch.id} }, :order => Student.sort_order) 
    end
  end
end
