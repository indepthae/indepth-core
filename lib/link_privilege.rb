module LinkPrivilege

  include ActionView::Helpers::TagHelper

  def link_to(*args, &block)
    permission_check = true
    if block_given?
      options = args.first || {}
      html_options = args[1]
      concat(link_to(capture(&block), options, html_options))
    else
      name = args.first
      options = args[1] || {}
      html_options = args[2]
      unless options[:permission].nil?
        if options[:permission] == false
          permission_check = false
        end
        options.delete(:permission)
      end
      
      url = case options
              when String
                options
              when :back
                @controller.request.env["HTTP_REFERER"] || 'javascript:history.back()'
              else
                self.url_for(options)
            end

      if html_options
        html_options = html_options.stringify_keys
        href = html_options['href']
        convert_options_to_javascript!(html_options, url)
        tag_options = tag_options(html_options)
      else
        tag_options = nil
      end

      if options.is_a? Hash
        path_details=options
      else
        path_details= begin
          ActionController::Routing::Routes.recognize_path(url.gsub(/#|#{Fedena.hostname}/, ''))
        rescue Exception => e
          ""
        end
      end

      path_details[:controller].blank? ? controller=nil : controller= path_details[:controller].to_s.gsub('/', '').to_sym
      path_details[:action].blank? ? action=nil : action=path_details[:action].to_s.gsub('/', '').to_sym
      display_link=true

      if permission_check
        
        if controller.present? and action.present?
          
          unless (permitted_to? action, controller)
            
            display_link=false
          end
        elsif action.present?
          unless (permitted_to? action)
            display_link=false
          end
        end
      end

      if display_link
        super
        # href_attr = "href=\"#{url}\"" unless href
        # "<a #{href_attr}#{tag_options}>#{name || url}</a>"
      else
        href_attr = ""
      end

    end
  end


  def link_to_remote(name, options = {}, html_options = nil)
    permission_check = true
    html_options ||= {}
    unless options[:url][:permission].nil?
      if options[:url][:permission] == false
          permission_check = false
        end
      options[:url].delete(:permission)
    end
    html_options[:href] ||= options[:url]
    (options[:url].present? and options[:url][:controller].present?) ? controller=options[:url][:controller].to_sym : controller=nil
    (options[:url].present? and options[:url][:action].present?) ? action= options[:url][:action].to_sym : action=nil
    if permission_check
      if controller.present? and action.present?
        if permitted_to? action, controller
          link_to_function(name, remote_function(options), html_options || options.delete(:html))
        end
      elsif action.present?
        if permitted_to? action
          link_to_function(name, remote_function(options), html_options || options.delete(:html))
        end
      else
        link_to_function(name, remote_function(options), html_options || options.delete(:html))
      end
    end
  end

  def link_present
    return true
  end

end
