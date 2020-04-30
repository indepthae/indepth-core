class PdfMaker

  def initialize(controller_name,action_name,folder=nil)

    @folder = folder ||= "tmp/#{controller_name}-#{action_name}"

    @controller = "#{controller_name}_controller".classify.constantize.new()
    @controller.action_name = action_name.to_s
    @controller.request = Rack::Request.new({})
    @controller.response = ActionController::Response.new()
    av=ActionView::Base.new(ActionController::Base.view_paths,{},@controller)
    av.instance_variable_set(:@template_format,:html)
    @controller.response.template=av
    @controller.instance_variable_set(:@template,av)
    @controller.session = {}
    @controller.params = {}

    av.class_eval do
      include ActionView::Helpers
      include ApplicationHelper
      include WickedPdfHelper
    end

  end

  def generate_pdf(file_name,options={}, &block)
    
    @controller.instance_eval(&block)
    pdf_text = @controller.send :render_to_string, {:pdf=>file_name}.merge(options)

    @controller.send :clean_temp_files

    FileUtils.mkdir_p(File.join(@folder)) unless File.directory? File.join(@folder)
    pdf_path = Rails.root.join(@folder,file_name+'.pdf')

    puts 'Creating' + pdf_path +' .'
    File.open(pdf_path, 'wb') do |file|
      file << pdf_text
    end

  end

end