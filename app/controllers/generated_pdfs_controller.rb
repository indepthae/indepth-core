class GeneratedPdfsController < ApplicationController
  filter_access_to :all
  
  def download_pdf
    file = GeneratedPdf.find(params[:id])
    send_file file.pdf.path, :type => file.pdf_content_type, :disposition => 'inline'
  end
  
end
