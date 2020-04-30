class DeleteDupEntriesAndAddUniqueIndexOnAssessmentScores < ActiveRecord::Migration
  def self.up
    
    #Making backup
    
    system("mkdir -p #{Rails.root.to_s}/uploads")
    config_file = YAML.load_file('config/database.yml')["production"]
    system ("mysqldump -u#{config_file['username']} -p#{config_file['password']} #{config_file['database']} assessment_scores > uploads/assessment_scores_20160330110725.sql")

    #Deleting entries for deleted exams

    delete <<-SQL
      delete from assessment_scores where assessment_scores.exam_id IS NOT NULL and assessment_scores.subject_id = 0;
    SQL

    #Deleting duplicate entries(if any) in case of co-scholastic

    delete <<-SQL
      delete dup.* from assessment_scores as dup inner join
    ( select min(id) as minId, batch_id,descriptive_indicator_id, subject_id, student_id from assessment_scores group by batch_id,descriptive_indicator_id, subject_id, student_id having count(*)>1 ) as save on
     save.batch_id=dup.batch_id and save.descriptive_indicator_id=dup.descriptive_indicator_id and dup.subject_id IS NULL and
     save.student_id=dup.student_id and save.minId <> dup.id;
    SQL

    #Modifying subject_id field

    change_column :assessment_scores, :subject_id, :integer, :default => 0, :null => false

    #Deleting entries where there is a cce_exam_category_id mismatch
    
    delete <<-SQL
    delete a.* from assessment_scores a inner join descriptive_indicators di on di.id=a.descriptive_indicator_id inner join fa_criterias fac on fac.id = di.describable_id inner join fa_groups fag on fag.id = fac.fa_group_id where fag.cce_exam_category_id != a.cce_exam_category_id;
    SQL

    #deleting duplicate entries from assessment_scores
    
    delete <<-SQL
       delete dup.* from assessment_scores as dup inner join
     ( select min(id) as minId, batch_id,descriptive_indicator_id, subject_id, student_id from assessment_scores group by batch_id,descriptive_indicator_id, subject_id, student_id having count(*)>1 ) as save on
     save.batch_id=dup.batch_id and save.descriptive_indicator_id=dup.descriptive_indicator_id and save.student_id=dup.student_id and  save.subject_id=dup.subject_id and save.minId <> dup.id;
    SQL

    #Adding unique index

    add_index :assessment_scores, [:batch_id,:descriptive_indicator_id,:subject_id,:student_id],:unique=>true, :name=>:batch_di_subject_student_unique_index
  end

  def self.down
  end
end
