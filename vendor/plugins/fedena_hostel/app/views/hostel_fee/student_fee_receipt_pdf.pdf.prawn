pdf.header pdf.margin_box.top_left do
if FileTest.exists?("#{RAILS_ROOT}/public/uploads/image/institute_logo.jpg")
logo = "#{RAILS_ROOT}/public/uploads/image/institute_logo.jpg"
else
logo = "#{RAILS_ROOT}/public/images/application/app_fedena_logo.jpg"
end
@institute_name=Configuration.get_config_value('InstitutionName');
@institute_address=Configuration.get_config_value('InstitutionAddress');
pdf.image logo, :position=>:left, :height=>50, :width=>50
pdf.font "Helvetica" do
      info = [[@institute_name],
        [@institute_address]]
pdf.move_up(50)
pdf.fill_color "97080e"
pdf.table info, :width => 400,
                :align => {0 => :center},
                :position => :center,
                :border_color => "FFFFFF"
      pdf.move_down(20)
      pdf.stroke_horizontal_rule
        end
end
pdf.move_down(100)
pdf.bounding_box([20,620], :width => 500,:align=>:center) do
pdf.text "Hostel Fees Receipt", :size => 14, :align=>:center
end
pdf.move_down(20)

fee_collection_detail =[["Student Name",@transaction.student.full_name],
 ["Fee Collection Name",@transaction.hostel_fee_collection.name],
["Batch",@transaction.hostel_fee_collection.batch.full_name],
["",""],
[ {:text=>"Rent",:style=>:bold} ,@transaction.rent ]]
pdf.table fee_collection_detail,
 :width => 500,
                :border_color => "000000",
                :header_color => "eeeeee",
                :header_text_color  => "97080e",
                :position => :center,
                :row_colors => ["FFFFFF","DDDDDD"],
                :align => { 0 => :left, 1 => :left}




pdf.footer [pdf.margin_box.left, pdf.margin_box.bottom + 25] do
     pdf.font "Helvetica" do
        signature = [[""]]
        pdf.table signature, :width => 500,
                :align => {0 => :right,1 => :right},
                :headers => ["Signature"],
                :header_text_color  => "DDDDDD",
                :border_color => "FFFFFF",
                :position => :center
        pdf.move_down(20)
        pdf.stroke_horizontal_rule
    end
end