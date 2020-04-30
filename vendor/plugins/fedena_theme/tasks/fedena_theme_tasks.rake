namespace :fedena_theme do
  desc "Install Fedena Theming Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_theme/public ."
    Rake::Task["css_themes:generate_color_css"].execute
    Rake::Task["css_themes:generate_font_css"].execute
  end
end
namespace :css_themes do
  desc "Create the directories and css files for various colors"
  task :generate_color_css => :environment do
    log = Logger.new("log/generate_css.log")
    begin
      colors = FedenaTheme::COLORS
      dir = "#{RAILS_ROOT}/public/stylesheets/themes"
      rtl_dir = "#{RAILS_ROOT}/public/stylesheets/rtl/themes"
      Dir.mkdir(dir) unless File.exists?(dir)
      Dir.mkdir(rtl_dir) unless File.exists?(rtl_dir)
      FileUtils.rm_rf(Dir.glob("#{dir}/*"))
      FileUtils.rm_rf(Dir.glob("#{rtl_dir}/*"))

      view_dir = File.dirname(__FILE__) + "/../app/views/themes"
      css_file = File.open(File.join(view_dir, "theme_css.html.erb"))
      rtl_css_file = File.open(File.join(view_dir, "theme_rtl_css.html.erb"))

      template = css_file.read()
      rtl_template = rtl_css_file.read()

      colors.each do |k,v|
        Dir.mkdir(dir+"/#{k}") unless File.exists?(dir+"/#{k}")
        Dir.mkdir(rtl_dir+"/#{k}") unless File.exists?(rtl_dir+"/#{k}")
        @current_theme = v[:color]
        @accent_color = v[:accent_color]
        @border_color = v[:border_color]
        output = ERB.new(template).result(binding)
        rtl_output = ERB.new(rtl_template).result(binding)
        File.open("#{dir}/#{k}/theme_css.css",'w+'){|f| f.write(output)}
        File.open("#{rtl_dir}/#{k}/theme_css.css",'w+'){|f| f.write(rtl_output)}
      end
    rescue Exception => err
      log.debug("#{err.message}")
      log.debug("------------")
      log.debug("#{err.backtrace.inspect}")
    end
  end

  desc "Create the directories and css files for various fonts"
  task :generate_font_css => :enviroment do
    log = Logger.new("log/generate_css.log")
    begin
      fonts = FedenaTheme::FONTS
      dir = "#{RAILS_ROOT}/public/stylesheets/fonts"
      Dir.mkdir(dir) unless File.exists?(dir)
      FileUtils.rm_rf(Dir.glob("#{dir}/*"))
      
      view_dir = File.dirname(__FILE__) + "/../app/views/themes"
      font_file = File.open(File.join(view_dir, "font.html.erb"))

      template = font_file.read()
      fonts.each do |k,v|
       Dir.mkdir(dir+"/#{k}") unless File.exists?(dir+"/#{k}")
       @font = v[:value]
       output = ERB.new(template).result(binding)
       File.open("#{dir}/#{k}/font.css",'w+'){|f| f.write(output)}
      end
    rescue Exception => err
      log.debug("#{err.message}")
      log.debug("---------------")
      log.debug("#{err.backtrace.inspect}")
    end
  end
end