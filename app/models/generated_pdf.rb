class GeneratedPdf < ActiveRecord::Base
  
  has_attached_file :pdf,
  :path => "uploads/:class/:attachment/:id_partition/:basename.:extension",
  :url => "/generated_pdfs/download_pdf/:id" 
  
  validates_attachment_content_type :pdf, :content_type =>'application/pdf' ,:message=>t('only_pdf_allowed'),:if=> Proc.new { |p| !p.pdf_file_name.blank? }
  
  belongs_to :corresponding_pdf, :polymorphic => true 
  
  def set_pdf_content(pdf_content,pdf_name, opts={})
    opts[:margin] ||= {:left=>0,:right=>0,:top=>0,:bottom=>0}
    opts[:encoding] ||= 'utf8'
    pdf_string = WickedPdf.new(WickedPdf.config[:wkhtmltopdf]).pdf_from_string(pdf_content, opts )
      
    tempfile = Tempfile.new([pdf_name.to_s , ".pdf"], Rails.root.join('tmp'))
    tempfile.binmode
    tempfile.write pdf_string
    tempfile.close
    self.pdf = File.open tempfile.path
    tempfile.unlink 
  end
  
end
