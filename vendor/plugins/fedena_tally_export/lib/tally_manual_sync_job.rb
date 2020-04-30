require 'nokogiri'
class TallyManualSyncJob
  def initialize(start_date, end_date)
    @start_date = start_date.to_date
    @end_date = end_date.to_date + 1.day
    @job_type = 1
  end

  def perform
    transactions = FinanceTransaction.all(:conditions => "finance_transactions.created_at >= '#{@start_date}' AND finance_transactions.created_at < '#{@end_date}' AND finance_transactions.lastvchid IS NULL AND finance_transaction_categories.tally_ledger_id IS NOT NULL", :joins => "INNER JOIN finance_transaction_categories ON finance_transactions.category_id = finance_transaction_categories.id")

    transactions.each do |trans|
      xml = fetch_xml(trans.id)
      tally_url = TallyExportConfiguration.get_config_value('TallyUrl')
      if tally_url[tally_url.length-1,1].to_s != "/"
        tally_url = tally_url + '/'
      end
      uri = URI.parse(tally_url)
      request = Net::HTTP::Post.new(uri.path)
      request.body = xml
      request.content_type="text/xml"

      begin
        res = Net::HTTP.start(uri.host, uri.port) do |http|
          http.request(request)
        end
      rescue Timeout::Error => e
        TallyExportLog.create(:finance_transaction_id => trans.id, :status => false, :message => "#{e.message}")
        return
      end

      xml_res = Nokogiri::XML(res.body)

      status = xml_res.at_css("STATUS").text unless xml_res.at_css("STATUS").nil?

      if status == '1'
        lastvchid = xml_res.at_css("LASTVCHID").text unless xml_res.at_css("LASTVCHID").nil?
        transaction = FinanceTransaction.find trans.id
        transaction.update_attributes(:lastvchid=> lastvchid.to_i)
        tally_log = TallyExportLog.find_by_finance_transaction_id trans.id
        if tally_log.nil?
          TallyExportLog.create(:finance_transaction_id => trans.id, :status => true, :message => "Success")
        else
          tally_log.update_attributes(:status => true, :message => "Success")
        end
      else
        error = xml_res.at_css("LINEERROR").text unless xml_res.at_css("LINEERROR").nil?
        tally_log = TallyExportLog.find_by_finance_transaction_id trans.id
        if tally_log.nil?
          TallyExportLog.create(:finance_transaction_id => trans.id, :status => false, :message => "#{error}")
        else
          tally_log.update_attributes(:status => false, :message => "#{error}")
        end
      end
    end
  end

  def fetch_xml(trans_id)
    trans = FinanceTransaction.find_by_id trans_id
    category = trans.category
    ledger = category.tally_ledger
    trans_amount = trans.amount

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.ENVELOPE {
        xml.HEADER {
          xml.VERSION "1"
          xml.TALLYREQUEST "Import"
          xml.TYPE "Data"
          xml.ID "Vouchers"
        }
        xml.BODY {
          xml.DESC {
            xml.STATICVARIABLES {
              xml.SVCURRENTCOMPANY "#{ledger.company_name}"
            }
          }
          xml.DATA {
            xml.TALLYMESSAGE {
              xml.VOUCHER {
                xml.DATE "#{trans.transaction_date.strftime("%Y%m%d")}"
                xml.NARRATION "#{trans.description}"
                xml.VOUCHERTYPENAME "#{ledger.voucher_name}"
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
            }
          }
        }
      }
    end

    return builder.to_xml
  end
end