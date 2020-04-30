class DeleteDuplicatesFromGuardians < ActiveRecord::Migration
  def self.up
    update <<-SQL
      update students s
      inner join guardians g on s.immediate_contact_id=g.id
      left outer join users u on u.id=g.user_id
      set s.immediate_contact_id = null where u.id is null
    SQL

    delete <<-SQL
      delete users.* from users
      left outer join guardians on users.id=guardians.user_id
      where users.parent = 1 and users.is_deleted = 0 and guardians.id is null
    SQL

    delete <<-SQL
      delete orig.* from guardians orig
      inner join (
        select count(distinct(s.immediate_contact_id)) as imc, g.id,g.ward_id,g.first_name,g.last_name,g.relation from guardians g
        left outer join students as s on s.immediate_contact_id=g.id
        group by g.ward_id,g.first_name,g.last_name,g.relation
        having count(g.id) > 1 and count(distinct(s.immediate_contact_id)) > 0
      ) as dup on dup.ward_id=orig.ward_id and dup.first_name=orig.first_name and dup.last_name=orig.last_name and dup.relation = orig.relation
      left outer join students as s on s.immediate_contact_id = orig.id
      where s.immediate_contact_id is null
    SQL

    delete <<-SQL
      delete orig.* from guardians orig
      inner join (
        select min(g.id) as minId ,g.ward_id,g.first_name,g.last_name,g.relation from guardians g
        left outer join students as s on s.immediate_contact_id=g.id
        group by g.ward_id,g.first_name,g.last_name,g.relation
        having count(g.id) > 1 and count(s.immediate_contact_id) = 0
      ) as dup on dup.ward_id=orig.ward_id and dup.first_name=orig.first_name and dup.last_name=orig.last_name and dup.relation = orig.relation and dup.minId<>orig.id
      left outer join students as s on s.immediate_contact_id = orig.id
    SQL

    delete <<-SQL
      delete users.* from users
      left outer join guardians on users.id=guardians.user_id
      where users.parent = 1 and users.is_deleted = 0 and guardians.id is null
    SQL

    update <<-SQL
      update students s
      inner join guardians g on s.immediate_contact_id=g.id
      left outer join users u on u.id=g.user_id
      set s.immediate_contact_id = null where u.id is null
    SQL
  end

  def self.down
  end
end
