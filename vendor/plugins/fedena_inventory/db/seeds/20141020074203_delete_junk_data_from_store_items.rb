ActiveRecord::Base.connection.execute("delete dup.* from store_items as dup inner join( select id,is_deleted from stores ) as save on save.id=dup.store_id and save.is_deleted=true and dup.is_deleted=false;")