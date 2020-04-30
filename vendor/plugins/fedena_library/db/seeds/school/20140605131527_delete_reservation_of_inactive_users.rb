@u_ids=User.inactive.collect(&:id)
BookReservation.find(:all,:conditions=>["user_id in (?)",@u_ids]).each do |reservation|
  reservation.destroy
end