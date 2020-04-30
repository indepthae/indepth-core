class AddUniqueIndexToExamScores < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("delete dup.* from exam_scores as dup inner join ( select min(id) as minId, exam_id, student_id from exam_scores group by exam_id,student_id having count(*)>1 ) as save on save.exam_id=dup.exam_id and save.student_id=dup.student_id and save.minId <> dup.id;")

    add_index :exam_scores, [:exam_id,:student_id],:unique=>true, :name=>:exam_scores_unique_index
  end

  def self.down
    remove_index :exam_scores,:name=>:exam_scores_unique_index,:unique=>true
  end
end
