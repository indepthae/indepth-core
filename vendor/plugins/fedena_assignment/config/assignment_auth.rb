authorization do

  role :student do

    has_permission_on [:assignment_answers],
      :to=>[
      :create,
      :new,
    ]do
      if_attribute :student_is_part_of_assignment => true
    end

    has_permission_on [:assignment_answers],
      :to=>[
      :show,
      :edit,
      :update,
      :download_attachment,
    ]do
      if_attribute :is_student_assignment_answer => true
    end

    has_permission_on [:assignments],
      :to=>[
      :assignment_student_list,
      :download_attachment,
      :index,
      :subject_assignments,
      :subjects_students_list,
    ]

    has_permission_on [:assignments],
      :to=>[
      :show,
    ]do
      if_attribute :student_is_part_of_assignment => true
    end

  end

  role :parent do

    has_permission_on [:assignments],
      :to=>[
      :show,
      :index,
      :download_attachment
    ],:join_by=> :and do
      if_attribute :assess_truth  => is {user.assignment_access?}
      if_attribute :id => is {user.parent_record.user_id}
    end

    has_permission_on [:assignment_answers],
      :to=>[
      :show,
      :download_attachment
    ],:join_by=> :and do
      if_attribute :id => is {user.parent_record.user_id}
    end
  end

  role :employee do

    has_permission_on [:assignments],
      :to=>[
      :assignment_student_list,
      :create,
      :destroy,
      :download_attachment,
      :index,
      :new,
      :subject_assignments,
      :subjects_students_list
    ]
    has_permission_on [:assignments],
      :to => [
      :show,
      :edit,
      :update
    ]do
      if_attribute :employees_with_access => contains {user.employee_entry}
    end

    has_permission_on [:assignment_answers],
      :to=>[
      :download_attachment,
      :evaluate_assignment,
      :show
    ]

  end

end
