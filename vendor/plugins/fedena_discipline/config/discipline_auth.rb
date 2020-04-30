authorization do

  role :admin do
    includes :discipline
  end
  role :employee do
    includes :discipline_view
  end
  role :student do
    includes :discipline_view
  end
  role :parent do
    includes :discipline_view
  end
  role :discipline do
    has_permission_on [:discipline_complaints],
      :to => [
      :index,
      :new,
      :create,
      :update,
      :download_attachment,
      :delete_attachment,
      :search_complaint_ajax,
      :show,
      :reply,
      :decision_remove,
      :decision_close,
      :search_complainee,
      :search_accused,
      :search_juries,
      :search_users,
      :create_comment,
      :destroy_comment,
      :list_comments
    ]
    has_permission_on [:discipline_complaints],
      :to => [
        :edit
      ], :join_by=> :and do
        if_attribute :decision_closed? => is {false}
        if_attribute :discipline_participations_user_include => does_not_contain {user}
      end
      has_permission_on [:discipline_complaints],
      :to => [
        :destroy
      ]do
        if_attribute :discipline_participations_user_include => does_not_contain {user}
      end
      has_permission_on [:discipline_complaints],
      :to => [
        :decision
      ]do
        if_attribute :discipline_participations_exclude_jury_user => is {true}
      end
  end
  role :discipline_view do
    has_permission_on [:discipline_complaints],
      :to => [
      :index,
      :search_complaint_ajax,
      :reply,
      :destroy_comment,
      :list_comments
    ]
    has_permission_on [:discipline_complaints],
      :to => [
        :create_comment
      ]do
        if_attribute :discipline_participations_user_entry => contains {user}
      end
    has_permission_on [:discipline_complaints],
      :to=>[
      :decision_remove,
      :decision_close,
      :decision
    ]do
      if_attribute :discipline_participations_exclude_jury_user => is {true}
    end

    has_permission_on :discipline_complaints, :to=>[:show,:download_attachment], :join_by=> :or do
      if_attribute :discipline_participation_user_ids=> contains {user.id}
      if_attribute :discipline_participation_user_ids=> contains {user.parent_record.user_id if user.parent and user.parent_record}
    end
  end
end
