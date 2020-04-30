# To change this template, choose Tools | Templates
# and open the template in the editor.

module Redactor::FormHelpers
  def redactor(object_name, field, options = {})
    if options.present?
      @callbacks = options[:callbacks] if options[:callbacks].present?
      @plugin_activation = options[:plugin] if options[:plugin].present?
      @activated_plugin_list = @plugin_activation.present? ? @plugin_activation.map{|k| k.to_s } : []
      @exclude_buttons = options[:exclude].present? ? options[:exclude].map(&:to_s) : []
    end
    id = redactor_element_id(object_name, field)
    @latex = options[:latex] if options[:latex].present?
    s3_present = File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml')
    unless(s3_present)
      s3_fields = ""
    else
      redactor_s3 = RedactorS3Helper.new
      policy = redactor_s3.policy_document
      sign = redactor_s3.upload_signature
      success_action_redirect = "#{Fedena.hostname}/redactor/post_upload"
      success_action_status = "201"

      s3_fields = "<input id='signature' type='hidden' name='signature' value='#{sign}'>" +
        "<input id='acl' type='hidden' name='acl' value='public-read'>" +
        "<input id='key' type='hidden' name='key' value='temp/#{(Time.now + (60*1000)).to_time.to_i}/${filename}'>" +
        "<input id='AWSAccessKeyId' type='hidden' name='AWSAccessKeyId' value='#{Config.access_key_id}'>" +
        "<input id='policy' type='hidden' name='policy' value='#{policy}'>" +
        "<input id='success_action_status' type='hidden' name='success_action_status' value='#{success_action_status}'>"
      #        "<input id='success_action_redirect' type='hidden' name='success_action_redirect' value='#{success_action_redirect}'>"
    end

    data_callbacks={}
    if @callbacks.present?
      @callbacks.each do |key, val|
        data_callbacks["data-#{key}"] = val
      end
    end

    if options[:ajax]
      inputs = "<input type='hidden' id='#{id}_hidden' name='#{object_name}[#{field}]'>\n"
    else
      inputs = s3_fields +
        ActionView::Helpers::InstanceTag.new(object_name, field, self, options.delete(:object)).to_text_area_tag(
        options.merge({ :id => id, :style => "background: transparent !important;border: 2px solid #ddd !important;",
            :data_plugins_i  => @activated_plugin_list.join(','), :data_buttons_e => @exclude_buttons.join(','),
            :class => "redactor_call redactor_call_style"}.merge(data_callbacks))) +
        "<input id='redactor_to_update' name='#{object_name}[redactor_to_update]' type='hidden' value=''>" +
        "<input id='redactor_to_delete' name='#{object_name}[redactor_to_delete]' type='hidden' value=''>"
    end

  end
  def redactor_element_id(object_name, field)
    "#{object_name.to_s.gsub('][','_').gsub('[','_').gsub(']','')}_#{field}"
  end

  def load_latex_preview

    content_for :redactor do
      "<script type='text/x-mathjax-config'>
    MathJax.Hub.Config({
    showMathMenu: false,
    messageStyle: 'none',
    positionToHash: false,
    displayAlign: 'left',
    MMLorHTML: { prefer: { Firefox: 'MML' } },
    tex2jax: {inlineMath: [['~~','~~']]}
    });
    MathJax.Hub.Queue(function () {
        parent.postMessage(
          'mathjax render successful',
          window.location.origin
        )
    });
  </script>
         <script type='text/javascript'  src='https://d1wab5as7kwc5w.cloudfront.net/MathJax/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>"
    end

  end

  def ping(url)
    regex = /^.*(http|https):\/\/(.*).*$/
    m = url.match(regex)
    url = $2 || url
    domain = url.split('/').first
    url_resource = url.split(domain).last
    begin
      if(url_resource.present?)
        return Net::HTTP.new("#{domain}").head(url_resource).kind_of? Net::HTTPOK
      else
        return Net::HTTP.new("#{domain}").head('/').kind_of? Net::HTTPOK
      end
    rescue
      return false
    end
  end

  def load_redactor_script
    s3_present = File.exist? File.join(::Rails.root, 'config', 'amazon_s3.yml')
    unless(s3_present)
      image_upload_options = "imageUpload: '/redactor/upload',
                                                uploadFields: {'authenticity_token':j('input[name=authenticity_token]').val()}"
      s3_fields = ""
      s3_image_upload_plugin = ""
      image_button = "image"
      #        latex_plugin = ""
      #        latex_html = ""
    else
      image_button = ""
      s3_image_upload_plugin = "s3_image_upload"
      redactor_s3 = RedactorS3Helper.new
      policy = redactor_s3.policy_document
      sign = redactor_s3.upload_signature
      success_action_redirect = "#{Fedena.hostname}/redactor/post_upload"
      success_action_status = "201"
      server = Config.s3_end_point_url || 's3.amazonaws.com'
      image_upload_options = "imageUpload: '#{Config.s3_url}/',
              uploadCrossDomain: true,
              uploadFields: {
                'key': '#key',
                'AWSAccessKeyId': '#AWSAccessKeyId',
                'acl': '#acl',
                'success_action_status':'201',
                //'success_action_redirect': '#success_action_redirect',
                'policy': '#policy',
                'signature': '#signature'
              } ," +
        "'public_bucket_url': '#{Config.s3_url_public}'," +
        #              'public_bucket_url': 'https://#{Config.bucket_public}.#{server}',
      "'valid_image_types' : '#{RedactorUpload::VALID_IMAGE_TYPES.join(',')}'"
      s3_fields = "<input id='signature' type='hidden' name='signature' value='#{sign}'>" +
        "<input id='acl' type='hidden' name='acl' value='public-read'>" +
        "<input id='key' type='hidden' name='key' value='temp/#{(Time.now + (60*1000)).to_time.to_i}'>" +
        "<input id='AWSAccessKeyId' type='hidden' name='AWSAccessKeyId' value='#{Config.access_key_id}'>" +
        "<input id='policy' type='hidden' name='policy' value='#{policy}'>" +
        "<input id='success_action_status' type='hidden' name='success_action_status' value='#{success_action_status}'>"
      #        "<input id='success_action_redirect' type='hidden' name='success_action_redirect' value='#{success_action_redirect}'>"
    end

    if(@latex && ping(FEDENA_SETTINGS[:mathjaxurl]))
      latex_plugin ="advanced"
      latex_js = "<script src='/javascripts/redactor/advanced.js' type='text/javascript'></script>"
      latex_html = "<div id='latex' style='display:none'>\
                              <div class='latex-editor'>\
                                <section>\
                                  <p>\
                                    Enter tex expression\
                                    <button class='latexp-preview-btn redactor_modal_btn'>Preview</button>\
                                  </p>\
                                </section>\
                                <textarea class='latex-expression' id='MathInput' name='latex-expression' rows='3' cols='64' type='text'></textarea>\
                                <br>\
                                <div class='tex2jax_process latex-preview-output'>\
                              </div>\
                              <footer padding: 0px 15px 10px;>\
                                <div class='footer-btns'>\
                                  <a href='#' class='redactor_modal_btn redactor_btn_modal_close'>Cancel</a>\
                                  <button id='latexp-link' class='redactor_modal_btn redactor_latex_insert_btn'>Insert</button>\
                                </div>\
                              </footer>\
                             </div>\
                            </div>"
      latex_js_include = "<script type='text/javascript' src='#{FEDENA_SETTINGS[:mathjaxurl]}'></script>"
    else
      latex_plugin = ""
      latex_js = ""
      latex_html = ""
    end

    direction = rtl? ? 'rtl':'ltr'
    content_for :head do
      stylesheet_link_tag "redactor/redactor","redactor/style"
    end

    if File.exist? File.join(::Rails.root,"/public/javascripts/redactor/langs/#{@lan}.js")
      lang_js = "#{@lan}"
    else
      lang_js = "en"
    end

    #       <script src='/javascripts/redactor/custom.js' type='text/javascript'></script>
    content_for :redactor do
      plugins = []
      plugins << "#{s3_image_upload_plugin}" #unless @exclude_buttons.include?('image')
      plugins << 'fontcolor' #unless @exclude_buttons.include?('fontcolor')
      plugins << "#{latex_plugin}"
      plugins += @activated_plugin_list if @activated_plugin_list.present?
      
      buttons = ['html', '|', 'bold', 'italic', 'underline','deleted','|', 'redo', 'undo', '|', 'selectall', '|', 'formatting', '|',
        'subscript','superscript', '|', 'unorderedlist', 'orderedlist', 'outdent', 'indent', '|', 'alignment', '|',
        'horizontalrule', '|', "#{image_button}" , 'video' , 'file', 'table', 'link']
      
      "<script src='/javascripts/redactor/fontcolor.js' type='text/javascript'></script>
      <script src='/javascripts/redactor/fontfamily.js' type='text/javascript'></script>
      #{'<script src=\'/javascripts/redactor/fontsize.js\' type=\'text/javascript\'></script>' if @plugin_activation.present? && @plugin_activation.include?(:fontsize)}
       #{latex_js}
       <script src='/javascripts/redactor/redactor.js' type='text/javascript'></script>
       #{latex_js_include}
       <script src='/javascripts/redactor/langs/#{lang_js}.js' type='text/javascript'></script>
       <script src='/javascripts/redactor/s3_image_upload.js' type='text/javascript'></script>
       <script>
  window.onload = function(){
    call_redactor_onload();
    j('html, body').animate({ scrollTop: 0 }, 'slow');

  };

  function call_redactor_onload(){
    j('.redactor_call').each(function(a,b){
      init_redactor(b);
    })
    j('#page-yield').append(\"#{latex_html}\");
    j('.redactor_box').find('textarea').removeClass('redactor_call_style');
  };

  function init_redactor(b){
    var plugins = ['#{plugins.join('\',\'')}'];
    var buttons = ['#{buttons.join('\',\'')}'];
    _buttons_exclude = j(b).attr('data_buttons_e') !== undefined ? j(b).attr('data_buttons_e').split(',') : [];
    _plugins_include = j(b).attr('data_plugins_i') !== undefined ? j(b).attr('data_plugins_i').split(',') : [];
    /*
    console.log(plugins);
    console.log(buttons);
    console.log(_plugins_include);
    console.log(_buttons_exclude);
    */
    filtered_buttons = buttons.filter( function( el ) {
      return _buttons_exclude.indexOf( el ) < 0;
    } );

    filtered_plugins = j.grep(plugins, function(element) {
      return j.inArray(element, _plugins_include ) !== -1;
    });
    /*
    console.log(filtered_plugins);
    console.log(filtered_buttons);
    console.log('-------------');
    */
    // exception to include image 
    if(plugins.indexOf('s3_image_upload') >= 0 && _buttons_exclude.indexOf('image') < 0){
      filtered_plugins.push('s3_image_upload');
    }
    // exception to include latex
    if(plugins.indexOf('#{latex_plugin}') >= 0 && _buttons_exclude.indexOf('#{latex_plugin}') < 0){
      filtered_plugins.push('#{latex_plugin}');
    }
    /*
    console.log(filtered_plugins);
    console.log(filtered_buttons);
    */
    /** remove **/
    j(b).removeAttr('data_buttons_e').removeAttr('data_plugins_i');

    j('#'+b.id).redactor({
      initCallback: window[j(b).data('oninit')],
      changeCallback: window[j(b).data('onchange')],
      plugins: ['fontcolor'].concat(filtered_plugins),
      buttons: filtered_buttons,
      buttonsCustom: {
        superscript: {
          title: 'Superscript',
          callback: function(event, key) {
            this.execCommand(event,'superscript');
          }
        },
        subscript: {
          title: 'Subscript',
          callback: function(obj, event, key) {
            this.execCommand('subscript');
          }
        },
        redo: {
          title: 'Redo',
          callback: function(event, key) {
            this.execCommand(event,'redo');
          }
        },
        undo: {
          title: 'Undo',
          callback: function(obj, event, key) {
            this.execCommand('undo');
          }
        },
        selectall: {
          title: 'Select all',
          callback: function(obj, event, key) {
            this.selectall = true;
            this.execCommand('selectall');
          }
        },
        paste: {
          title: 'Paste',
          callback: function(obj, event, key) {
            //this.selectall = true;
            this.execCommand('inserthtml');
          }
        }
      },
      focus: true,      
      direction: '#{direction}',
      lang: '#{lang_js}',
      #{image_upload_options},
      imageUploadErrorCallback: function(json){
        j('#redactor_upload_errors_'+b.id).attr('style','display:block');
        j('#redactor_upload_errors_'+b.id).html(json.error_message);
        error_height = j('#redactor_upload_errors_'+b.id).outerHeight(true);
        editor_height = j('#redactor_upload_errors_'+b.id).parent().find('.redactor_editor').height();
        j('#redactor_upload_errors_'+b.id).parent().find('.redactor_editor').attr('style','height:'+(editor_height-error_height)+'px !important');
      },
      imageDeleteCallback: function(image){
        image_location = image[0].src;
        reg = /^.*uploads([0-9\\/]*)\\/images.*$/;
        old_ids_to_delete = j('#redactor_to_delete').val();
        old_ids_to_update = j('#redactor_to_update').val();
        if(reg.match(image_location)){
          image_location.match(reg);
          new_id_to_delete = parseInt(RegExp.$1.split('/').join(''));
          if(old_ids_to_delete == ''){
            new_ids_to_delete = [ new_id_to_delete ];
          }else{
            new_ids_to_delete = old_ids_to_delete.split(',');
            new_ids_to_delete.push(new_id_to_delete);
            new_ids_to_delete = new_ids_to_delete.join(',');
          }
          if(old_ids_to_update != ''){
            added_ids = old_ids_to_update.split(',');
            if(added_ids.include(new_id_to_delete)){
              added_ids.splice(added_ids.indexOf(new_id_to_delete.toString()),1);
            }
          }
          j('#redactor_to_delete').val(new_ids_to_delete);
          j('#redactor_to_update').val(added_ids.join(','));
        }
      },
      imageUploadCallback: function(image, json){
        new_id_to_update = ''
        if(json !== undefined){ new_id_to_update = json.id; }
        if(image !== undefined){ new_id_to_update = image.id; }
        //new_id_to_update = (json !== undefined) ? json.id : '';
        //new_id_to_update = image.id;        
        old_ids_to_update = j('#redactor_to_update').val();
        if(old_ids_to_update == ''){
          new_ids_to_update = [ new_id_to_update ]
        }else{
          new_ids_to_update = old_ids_to_update.split(',');
          new_ids_to_update.push(new_id_to_update);
          new_ids_to_update = new_ids_to_update.join(',');
        }
        j('#redactor_to_update').val(new_ids_to_update);
      }
    });

    j('#'+b.id).parent().prepend('<div class=\"redactor_upload_errors\" id=\"redactor_upload_errors_'+b.id+'\"></div>');

    j('.redactor_editor').find('iframe').each(function(a,b){
      if(b.src.indexOf('youtube.com')>=0 && b.src.indexOf('wmode')==-1){
        b.src = b.src+'?wmode=opaque';
      }
    });
    j('.redactor_box').on('click',function(){
      if(j('#redactor_upload_errors_'+b.id).html().length != 0){
        j('#redactor_upload_errors_'+b.id).attr('style','');
        j('#redactor_upload_errors_'+b.id).html('');
        j('#redactor_upload_errors_'+b.id).parent().find('.redactor_editor').removeAttr('style');
      }
    })
  }
</script>"
      #        if s3_present
      #        "

      #<div id='fedena_redactor_modal_overlay'></div>
      #        <div id='fedena_redactor_modal' class='ui-draggable'>
      #	<div id='fedena_redactor_modal_close'>×</div>
      #	<header id='fedena_redactor_modal_header' style='cursor: move;'>Insert Image</header>
      #	<div id='fedena_redactor_modal_inner'>
      #		<section>
      #			<div id='fedena_redactor_tabs'><a href='#' class='fedena_redactor_tabs_act'>Upload</a></div>
      #			<div id='fedena_redactor-progress' class='fedena_redactor-progress fedena_redactor-progress-striped' style='display: none;'>
      #				<div id='fedena_redactor-progress-bar' class='fedena_redactor-progress-bar' style='width: 100%;'></div>
      #			</div>
      #			<form id='fedena_redactorInsertImageForm' method='post' action='' enctype='multipart/form-data'>
      #				<div id='fedena_redactor_tab1' class='fedena_redactor_tab'>
      #						<input type='file' id='fedena_redactor_file' name='file'>
      #				</div>
      #			</form>
      #		</section>
      #		<footer>
      #			<button class='fedena_redactor_modal_btn fedena_redactor_btn_modal_close'>Cancel</button>
      #			<input type='button' name='upload' class='fedena_redactor_modal_btn fedena_redactor_modal_action_btn' id='fedena_redactor_upload_btn' value='Insert'>
      #		</footer>
      #	</div>
      #</div>"
      #        else
      #          ""
      #        end
    end
  end
end
module ActionView
  module Helpers
    class FormBuilder
      def redactor(method, options = {})
        @template.redactor(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end