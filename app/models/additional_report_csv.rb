class AdditionalReportCsv < ActiveRecord::Base
  require 'securerandom'
  serialize :parameters, Hash
  has_attached_file :csv_report,
    :url => "/report/csv_report_download/:id",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :max_file_size => 10.megabytes,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :csv_report, :less_than => 10.megabytes,\
    :message=>'must be less than 10 MB.',:if=> Proc.new { |p| p.csv_report_file_name_changed? }

  def csv_generation
    I18n.locale = self.parameters[:locale] unless parameters[:locale].nil?
    method_name=self.method_name
    result=self.model_name.camelize.constantize.send(method_name,self.parameters)
    data = result
#    fields = result.second
    file_path="tmp/#{SecureRandom.random_number(Time.now.strftime("%H%M%S%d%m%Y").to_i)}_#{method_name_translation}.csv"
    FasterCSV.open(file_path, "wb") do |csv|
      data.each do |row_data|
#        row_data = config_data(fields,h,row_data) #unless i==0
        csv << row_data
      end
    end
    self.csv_report = open(file_path)
    self.status = false
    if self.save
      File.delete(file_path)
    else
     self.update_attribute(:status, false) 
    end
  end

  def config_data fields,data_fields,data_row
    fields.each_with_index do |a,b|
      if(a!='-')
        data_type = data_fields[a.to_s]
        case data_type
        when :date
          r = format_date(data_row[b])
          data_row[b] = r.present? ? r : data_row[b]
        when :datetime
          r = format_date(data_row[b],:format=>:short_date)
          data_row[b] = r.present? ? r : data_row[b]
        when :time
          r = format_date(data_row[b],:format=>:time)
          data_row[b] = r.present? ? r : data_row[b]
        end
      end
    end
    return data_row
  end
  
  def method_name_translation
    t("reports_name.#{method_name}")
  end

end
