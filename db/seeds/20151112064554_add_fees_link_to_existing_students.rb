fees_link = MenuLink.find_by_name_and_link_type("fees_text","own")
if fees_link
  insert_query = "insert into user_menu_links (user_id,menu_link_id,school_id,created_at,updated_at) select id, #{fees_link.id}, school_id, NOW(), NOW() from users where student=1 or parent=1;"
  ActiveRecord::Base.connection.execute(insert_query)
end