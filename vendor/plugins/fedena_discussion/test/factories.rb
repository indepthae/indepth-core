Factory.define :master_admin_user, :class => User do |u|
  u.sequence(:username) { |n| "admin#{n}" }
  u.password { |u1| "#{u1.username}123" }
  u.sequence(:first_name){ |n| "Fedena Master #{n}" }
  u.sequence(:last_name) { |n| " Admin #{n}"}
  u.email { |u1| "master#{u1.username}@fedena.com" }
  u.role 'Admin'
  u.school_id           0
end

Factory.define :admin_user, :class => User do |u|
  u.sequence(:username) { |n| "admin@#{n}" }
  u.password { |u1| "#{u1.username}123" }
  u.first_name 'Fedena'
  u.sequence(:last_name) { |n| "Admin#{n}"}
  u.sequence(:email) { |u| "admin_#{u}@fedena.com" }
  u.role 'Admin'
  u.school_id           1
end

Factory.define :employee_user, :class => User do |u|
  u.sequence(:username) { |n| "emp#{n}" }
  u.password            { |u1| "#{u1.username}123" }
  u.email               { |u1| "#{u1.username}@fedena.com" }
  u.first_name          'John'
  u.last_name           'Doe'
  u.role                'Employee'
  u.school_id           1
end


Factory.define :group do |s|
  s.group_name  "Test Group"
  s.association :user,:factory=>:master_admin_user
  s.members {|m| [m.association(:admin_user)]}
end

Factory.define :group_post do |s|
  s.association :group
  s.association :user,:factory=>:master_admin_user
  s.post_title  "Test Post Title"
  s.post_body   "Test Post Body"
end

Factory.define :group_file do |s|
  s.association :group
  s.doc_file_name     "Screenshot2.png"
  s.doc_content_type  "image/png"
end

Factory.define :group_member do |s|
  s.association :group
  s.association :user,:factory=>:admin
  s.is_admin    true
end

Factory.define :group_post_comment do |s|
  s.association :group_post
  s.association :user_id,:factory=>:master_admin_user
  s.comment_body  "Test Comment Body"
end

Factory.define :privilege do |s|
  s.name  "GroupCreate"
end
