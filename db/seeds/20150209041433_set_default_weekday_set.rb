multischool=MultiSchool rescue nil
update_weekday_set=unless(multischool)
  "UPDATE weekday_sets SET is_common=1 where id=1;"
else
  "UPDATE weekday_sets AS ws
  JOIN
    ( SELECT school_id, MIN(id) AS date
      FROM weekday_sets
      GROUP BY school_id
    ) AS c
    ON  ws.school_id = c.school_id
    AND ws.id = c.date
SET
   ws.is_common = 1 ;"
end
RecordUpdate.connection.execute(update_weekday_set)