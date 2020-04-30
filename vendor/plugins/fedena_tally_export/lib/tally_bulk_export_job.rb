require 'nokogiri'
class TallyBulkExportJob
  def initialize(start_date, end_date, ledger_ids)
    @start_date = start_date.to_date
    @end_date = end_date.to_date + 1.day
    @ledger_ids = ledger_ids.split(',')
    @job_type = 1
  end

  def perform
    ledgers = TallyLedger.all(:conditions=>{:id => @ledger_ids})
    categories = ledgers.map{|l| l.finance_transaction_categories.map{|c| c.id } }.flatten
    transactions = FinanceTransaction.all(:conditions => "created_at >= '#{@start_date}' AND created_at < '#{@end_date}' AND category_id IN (#{categories.join(',')}) AND lastvchid IS NULL", :include =>  {:category => :tally_ledger })

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ENVELOPE {
        xml.HEADER {
          xml.VERSION "1"
          xml.TALLYREQUEST "Import"
          xml.TYPE "Data"
          xml.ID "Vouchers"
        }
        xml.BODY {
          xml.DESC ""
          xml.DATA {
            xml.TALLYMESSAGE {
              i = 0
              transactions.each do |trans|
                trans_amount = trans.amount
                unless trans_amount == 0
                  xml.VOUCHER {
                    category = trans.category
                    ledger = category.tally_ledger
                    xml.DATE "#{trans.transaction_date.strftime("%Y%m%d")}"
                    xml.NARRATION "#{trans.description}"
                    xml.VOUCHERTYPENAME "#{ledger.voucher_name}"
                    xml.VOUCHERNUMBER "#{i+=1}"
                    xml.send("ALLLEDGERENTRIES.LIST") {
                      xml.LEDGERNAME "#{ledger.ledger_name}"
                      xml.ISDEEMEDPOSITIVE "#{category.is_income? ? "No" : "Yes"}"
                      xml.AMOUNT "#{category.is_income? ? "" : "-"}#{trans_amount}"
                    }
                    xml.send("ALLLEDGERENTRIES.LIST") {
                      xml.LEDGERNAME "#{ledger.account_name}"
                      xml.ISDEEMEDPOSITIVE "#{category.is_income? ? "Yes" : "No"}"
                      xml.AMOUNT "#{category.is_income? ? "-" : ""}#{trans_amount}"
                    }
                  }
                end
              end
            }
          }
        }
      }
    end
    xml_file_name =""
    file_name = "tally_#{Time.now.strftime("%Y%m%d%H%M%S")}.xml"
    if defined?(MultiSchool)
      FileUtils.mkpath "#{Rails.root}/uploads/tally_exports/#{@school_id}/" unless File.exists? "#{Rails.root}/uploads/tally_exports#{@school_id}/"
      xml_file_name = "#{Rails.root}/uploads/tally_exports/#{@school_id}/#{file_name}"
    else
      FileUtils.mkpath "#{Rails.root}/uploads/tally_exports" unless File.exists? "#{Rails.root}/uploads/tally_exports"
      xml_file_name = "#{Rails.root}/uploads/tally_exports/#{file_name}"
    end
    File.open(xml_file_name, 'w') {|f| f.write(builder.to_xml) }

    file = File.open("#{xml_file_name}")

    if file
      if TallyExportFile.create(:export_file => file)
        begin
          FileUtils.rm file.path
        rescue

        end
      end
    end
  end

end