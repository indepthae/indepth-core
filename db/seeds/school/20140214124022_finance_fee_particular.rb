date= Date.strptime("{ 2014, 1, 22 }", "{ %Y, %m, %d }")
FinanceFeeCategory.find(:all,:group=>'concat(name,description)',:conditions=>"is_deleted=#{false} and is_master=#{true} and created_at<'#{date}'").each do |a|
  FinanceFeeCategory.find(:all,:conditions=>["id<>'#{a.id}' and name=? and is_deleted='#{false}' and description=? and created_at<'#{date}'","#{a.name}","#{a.description}"]).each do |b|
     #particulars=FinanceFeeParticular.find(:all,:conditions=>"finance_fee_category_id=#{b.id} and batch_id=#{b.batch_id} and is_deleted=#{false}")
     FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `finance_fee_category_id` = '#{a.id}' WHERE `finance_fee_category_id`=#{b.id} and `batch_id`=#{b.batch_id} and `is_deleted`=#{false};")
     FeeDiscount.connection.execute("UPDATE `fee_discounts` SET `finance_fee_category_id` = '#{a.id}' WHERE `finance_fee_category_id`=#{b.id} and `batch_id`=#{b.batch_id} and `is_deleted`=#{false};")
    #discounts=FeeDiscount.find(:all,:conditions=>"finance_fee_category_id=#{b.id} and batch_id=#{b.batch_id} and is_deleted=#{false}")
    #particulars.each do |particular|

      #attributes=particular.attributes.delete_if{|key,values| ["id","finance_fee_category_id"].include? key}
      #attributes["finance_fee_category_id"]=a.id
      #FinanceFeeParticular.create(attributes)
    end
    #discounts.each do |discount|
 #p "cat=#{a.id}"
 #p "discount#{discount.id}"
#      attributes=discount.attributes.delete_if{|key,values| ["id","finance_fee_category_id"].include? key}
#      attributes["finance_fee_category_id"]=a.id
      #FeeDiscount.connection.execute("INSERT INTO `fee_discounts` SET `finance_fee_category_id` = '#{a.id}',`batch_id`='#{discount.batch_id}',`name`='#{discount.name}',`discount`='#{discount.discount}',`is_amount`='#{discount.is_amount}',`receiver_id`='#{discount.receiver_id}',`receiver_type`='#{discount.receiver_type}',`is_deleted`='#{discount.is_deleted}'")
#      dis=FeeDiscount.new(attributes)
#      dis.save(false)
    #end
  #end
end