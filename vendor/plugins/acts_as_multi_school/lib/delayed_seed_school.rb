class DelayedSeedSchool
  def perform
    system("rake fedena:seed_schools")
  end
end