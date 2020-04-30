module AdditionalFields
  def get_fields
    @additional_details_hsh = {}
    active.each do |field|
      name = (field.name.downcase.gsub(" ","_") + "_additional_fields_" + field.id.to_s).to_sym
      @additional_details_hsh[name] = field.name
    end
    @additional_details_hsh
  end
end
