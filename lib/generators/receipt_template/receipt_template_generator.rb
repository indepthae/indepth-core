class ReceiptTemplateGenerator < Rails::Generator::Base
  def initialize(*runtime_args)
    super(*runtime_args)
    @receipt_args = runtime_args
    @template_name = "_template_" + runtime_args.first.first.parameterize.underscore.to_s.to_s

    @stylesheet_name=@template_name+".css"
    @partial_name=@template_name+".html.erb"
    puts @template_name
  end

  def manifest
    record do |m|
      m.directory "public/stylesheets/_receipt_templates"
      m.directory "app/views/_receipt_templates"
      m.template "stylesheet.css",File.join("public/stylesheets/_receipt_templates", @stylesheet_name)
      m.template "stylesheet.css",File.join("public/stylesheets/_receipt_templates/rtl", @stylesheet_name)
      m.template "template.html.erb",File.join("app/views/_receipt_templates", @partial_name),
        :assigns => { :template_name => @template_name }
    end

  end
end
