// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var tooltip_timer, delay = 1000, field_error = true;

document.observe("dom:loaded", function() {
    $$('object').each(function(obj){
        a  = document.createElement('param');
        a.name = 'wmode';
        a.value = 'transparent'; 
        obj.appendChild(a);
    });  

    Ajax.InPlaceEditor.addMethods({
        getText: function($super){
            if(this.element.textContent)
            {
                return this.element.textContent
            }
            else
            {
                return this.element.innerText
            }
        }
    });

    //    load_menu_from_plugins();
    j("input[type=password]").each(function(){
        j(this).bind('keypress', 'q', function(e) {
            e.stopPropagation();
        });
    });
});

function make_popup_box(elm, type, text, options)
{
    var defaults = {
        ok: 'OK',
        cancel: 'Cancel',
        submit: 'Submit',
        title: '',
        description: '',
        link: j(elm).attr('href'),
        field_name: '',
        input_type: 'text_input',
        mandatory: false,
        error_msg: "This field is required",
        return_status: false
    };
    options = j.extend({}, defaults, options);
    remove_popup_box();
    build_modal_box(options);
    if(type == 'alert')
        build_alert_popup_box(text, options)
    else if(type == 'confirm')
        build_confirm_popup_box(text, options);
    else if(type == 'prompt')
        build_prompt_popup_box(text, options)
    else if(type=="refresh_confirm"){
        build_alert_popup_box(text, options);
        j('.MB_close_div').hide();
    }
    j(document).scrollTop(0);
    j('#popup_window #popup_footer > #yes').click(function(){
        send_request(type, options)
    });
    return false;
}
function send_request(type, options){
    j('#popup_window #popup_footer > #yes').unbind('click')
    if(type == 'alert')
        remove_popup_box();
    else if(type == 'confirm')
        redirect_action(options, type);
    else if(type == 'prompt')
        redirect_action(options, type);
    else if(type=='refresh_confirm')
        reload_confirm_alert_box();
}

function reload_confirm_alert_box(){
    location.reload(true);
}

function build_modal_box(options) { 
    if (!(j("#popup_window").css('visibility'))){
        overlay = j('<div></div>', {
            'id' : 'popup_box_overlay'
        });
        par_div = j('<div></div>', {
            'id' : 'popup_window',
            'class' : options.popup_class
        });
        frame = j('<div></div>', {
            'id' : 'popup_frame'
        });
        head = j('<div></div>', {
            'id' : 'popup_header_part',
            'class' : 'part'
        });
        header =j('<h4></h4>', {
            'text' : options.title
        });
        close_link = j('<div></div>', {
            'id' : 'MB_close',
            'class': 'MB_close_div',
            'onclick' : 'remove_popup_box()'
        });
        head.append(header);
        head.append(close_link);
        frame.append(head);
        par_div.append(frame);
        content = j('<div></div>', {
            'id' : 'popup_content',
            'class' : 'part'
        });
        frame.append(content);
        footer = j('<div></div>', {
            'id' : 'popup_footer',
            'class' : 'part'
        });
        frame.append(footer);
        j('#page-yield').append(overlay);
        j('#page-yield').append(par_div);
        j('#popup_window').offset({
            left : (j('body').width() - j('#popup_window').width())/2
        });
        j('#popup_window')[0].scrollIntoView();
    }
}
function build_alert_popup_box(text, options)
{
    par_div = j('#popup_window #popup_content');
    message = j('<p></p>',{
        'id' : 'confirmation',
        'html' : text
    });
    par_div.append(message);
    footer = j('#popup_window #popup_footer');
    ok = j('<div></div>', {
        'id' : 'yes',
        'class' : 'submit-button',
        'text' : options.ok
    });
    footer.append(ok);
}
function build_confirm_popup_box(text, options)
{
    par_div = j('#popup_window #popup_content');
    message = j('<p></p>',{
        'id' : 'confirmation',
        'html' : text
    });
    par_div.append(message);
    footer = j('#popup_window #popup_footer');
    ok = j('<div></div>', {
        'class' : 'submit-button',
        'text' : options.ok,
        'id' : 'yes'
    });
    cancel = j('<div></div>', {
        'class' : 'submit-button',
        'text' : options.cancel,
        'onclick' : "remove_popup_box()"
    });
    footer.append(ok);
    footer.append(cancel);
}
function build_prompt_popup_box(text, options)
{
    par_div = j('#popup_window #popup_content');
    if (options.description != '') {
        message = j('<p></p>', {
            'id': 'confirmation',
            'html': options.description
        });
        par_div.append(message);
    }
    content = j('<div></div>', {
        'class' : 'label-field-pair'
    });
    label = j('<label></label>',{
        'text' : text
    });
    text_input_bg = j('<div></div>', {
        'class' : 'text-input-bg'
    });
    if(options.input_type == 'text_input')
        input = j('<input>', {
            'name' : options.field_name,
            'id' : 'prompt_value',
            'type' : 'text',
            'size' : 30
        });
    else if (options.input_type == 'checkbox')
        input = j('<input>', {
            'name': options.field_name,
            'id': 'prompt_value',
            'type': 'checkbox'
        });
    else
        input = j('<textarea></textarea>', {
            'name' : options.field_name,
            'id' : 'prompt_value',
            'type' : 'text',
            'cols' : 30,
            'rows' : 3
        });
    text_input_bg.append(input);
    content.append(label);
    content.append(text_input_bg);
    par_div.append(content);
    footer = j('#popup_window #popup_footer');
    submit = j('<div></div>', {
        'class' : 'submit-button prompt_ok',
        'id' : 'yes',
        'text' : options.submit
    });
    cancel = j('<div></div>', {
        'class' : 'submit-button',
        'text' : options.cancel,
        'onclick' : "remove_popup_box()"
    });
    footer.append(submit);
    footer.append(cancel);
}
function remove_popup_box()
{
    j('#popup_window').remove();
    j('#popup_box_overlay').remove();
}
function redirect_action(options, type)
{
    if(options.mandatory && (j('#popup_content #prompt_value').val().length == 0))
        field_error = false
    if(field_error){
        if(options.return_status)
            return true;
        else {
            if(options.field_name == null)
                window.location = options.link;
            else
                window.location = options.link + (options.link.split('?')[1] ? '&':'?') + options.field_name + "=" + j('#popup_content #prompt_value').val();
        }
    }
    else{
        make_error_message(options.error_msg)
        j('#popup_window #popup_footer > #yes').click(function(){
            send_request(type, options)
        });
    }
    field_error = true;
}
function make_error_message(message){
    j('#popup_content .label-field-pair .wrapper').remove()
    wrapper = j('<div></div>', {
        'class' : 'wrapper'
    });
    error_icon = j('<div></div>', {
        'class' : 'error-icon'
    });
    error_msg = j('<div></div>', {
        'class' : 'error-msg',
        'html' : message
    });
    wrapper.append(error_icon);
    wrapper.append(error_msg);
    j('#popup_content .label-field-pair').append(wrapper);
}
function build_tooltip_info(){
    elm = this;
    delay_tooltip=parseInt(j(elm).attr('delay')) || delay
    tooltip_timer = setTimeout(function() {
        if(j(elm).parent().attr('class') != "tooltip_wrapper")
        {
            wrapper = j('<div></div>', {
                'class' : 'tooltip_wrapper'
            });
            info = j('<div></div>', {
                'class' : 'tooltip_info',
                'html' : j(elm).attr('tooltip')
            });
            j(elm).wrap(wrapper);
            info.insertAfter(j(elm));
            align_tooltip(elm);
        }
    }, delay_tooltip);
}

function remove_tooltip_info(){
    j(this).siblings('.tooltip_info').remove();
    if(j(this).parent('.tooltip_wrapper').length > 0)
        j(this).unwrap();
    clearTimeout(tooltip_timer);
}

function align_tooltip(elm) {
    element = j(elm).parent();
    tooltip = j(elm).siblings('.tooltip_info');
    window_left = j(window).scrollLeft();
    window_width = j(window).outerWidth();
    window_right = window_width + window_left;
    element_left = element.offset().left;
    element_width = element.outerWidth();
    element_right = element_width + element_left;
    tooltip_left = tooltip.offset().left;
    tooltip_width = tooltip.outerWidth();
    tooltip_right = tooltip_width + tooltip_left;
    tooltip_border = parseInt(window.getComputedStyle(tooltip[0], '::after').getPropertyValue('border-right-width').replace('px',''));
    flag = (j('html').attr('dir') == 'ltr')
    if((element_right > window_left) && (element_left < window_right)){
        if(element_left < window_left){
            tooltip_left_pos = (window_left - element_left) + 'px';
            tooltip_info_right = 'auto';
            if(flag)
                tooltip_info_left = (element_right - window_left)/2 + 'px';
            else
                tooltip_info_left = ((element_right - window_left)/2 - tooltip_border) + 'px';
        }
        else if(element_left == window_left){
            tooltip_left_pos = '0px';
            tooltip_right_pos = '';
            tooltip_info_right = 'auto';
            if(flag)
                tooltip_info_left = (element_width)/2 + 'px';
            else
                tooltip_info_left = ((element_width)/2 - tooltip_border) + 'px';
        }
        else{
            if(element_right < window_right){
                left_pos = element_left + (element_width - tooltip_width)/2;
                right_pos = left_pos + tooltip_width;
                if((left_pos > window_left) && (right_pos < window_right)){
                    tooltip_left_pos = ((element_width - tooltip_width)/2) + 'px';
                    tooltip_right_pos = '';
                    tooltip_info_right = '50%';
                    tooltip_info_left = '50%';
                }
                else{
                    if(left_pos < window_left){
                        tooltip_left_pos = (window_left - element_left) + 'px';
                        tooltip_right_pos = '';
                        tooltip_info_right = 'auto';
                        if(flag)
                            tooltip_info_left = ((element_left - window_left) + element_width/2) + 'px';
                        else
                            tooltip_info_left = (((element_left - window_left) + element_width/2) - tooltip_border) + 'px';
                    }
                    else{
                        tooltip_left_pos = '';
                        tooltip_right_pos = (element_right - window_right) + 'px';
                        tooltip_info_left = 'auto';
                        if(flag)
                            tooltip_info_right = (((window_right - element_right) + element_width/2) - tooltip_border) + 'px';
                        else
                            tooltip_info_right = ((window_right - element_right) + element_width/2) + 'px';
                    }
                }
            }
            else if(element_right == window_right){
                tooltip_left_pos = '';
                tooltip_right_pos = '0px';
                tooltip_info_left = 'auto';
                if(flag)
                    tooltip_info_right = ((element_width)/2 - tooltip_border) + 'px';
                else
                    tooltip_info_right = (element_width)/2 + 'px';
            }
            else{
                tooltip_left_pos = '';
                tooltip_right_pos = (element_right - window_right) + 'px';
                tooltip_info_left = 'auto';
                if(flag)
                    tooltip_info_right = ((window_right - element_left)/2 - tooltip_border) + 'px';
                else
                    tooltip_info_right = (window_right - element_left)/2  + 'px';
            }
        }
    }
    tooltip.css({
        'left' : tooltip_left_pos,
        'right': tooltip_right_pos
    });
    j("#dynamic").text(".tooltip_info:before{left : "+ tooltip_info_left +"; right : "+ tooltip_info_right +"} .tooltip_info:after{left : "+ tooltip_info_left +"; right : "+ tooltip_info_right +"}");
    align_top(elm);
}

function align_top(elm){
    element = j(elm).parent();
    tooltip = j(elm).siblings('.tooltip_info');
    top_pos = j(elm).position().top;
    elm_outer_height = j(elm).outerHeight(true);
    tooltip.css({
        'top' : (top_pos + elm_outer_height) + 'px'
    });
    footer_top = j('#footer').offset().top;
    element_top = element.offset().top;
    element_height = element.outerHeight();
    tooltip_height = tooltip.outerHeight();
    if(footer_top < (element_top + element_height + tooltip_height))
    {
        tooltip.addClass('upside_down');
        tooltip.css({
            'top' : (top_pos - tooltip_height) + 'px'
        });
    }
    else
        tooltip.removeClass('upside_down');
}
jQuery(document).ready(function(){
    j("<style type='text/css' id='dynamic' />").appendTo("head");
    jQuery(document.body).on('mouseover', '[tooltip]', build_tooltip_info);
    jQuery(document.body).on('mouseout', '[tooltip]', remove_tooltip_info);

    // help wizard scripts
    j('.wizard_bar').click(function(){
        j('.wizard_content').slideToggle(function(){

            document.cookie='help_wizard=0; expires='+new Date(1900,0,1).toString()+'path='+document.location.pathname+';';
            document.cookie='help_wizard=1; expires='+new Date(1900,0,1).toString()+'path='+document.location.pathname+';';

            if(j('.wizard_content').is(':hidden')){
                j('.wizard_bar__action').text('Show more');
                j('.wizard').addClass('is_collapsed');
                document.cookie='help_wizard=0; path='+document.location.pathname+';';
            }
            else{
                j('.wizard_bar__action').text('Hide');
                j('.wizard').removeClass('is_collapsed');
                document.cookie='help_wizard=1; path='+document.location.pathname+';';
            }
        })
    })

})

Ajax.Responders.register({
    onComplete: function(request,response,options) {
        if (409 == response.status){
            if(j('#MB_window').length>=1){
                Modalbox.hide();
            }
            make_popup_box('',"refresh_confirm","Duplicate request received. Please refresh the page to proceed",{
                'ok':'Refresh',
                'title':""
            });
        }
        else if (403 == response.status){
            if(j('#MB_window').length>=1){
                Modalbox.hide();
            }
            make_popup_box('',"refresh_confirm","You are not permitted to perform this action",{
                'ok':'Refresh',
                'title':""
            });
        }
        else if (200 == response.status){
            if (j('#session_fingerprint').length){
                j('#session_fingerprint').val(response.getHeader('session_fingerprint'));
            }

        }
    }
});
jQuery.ajaxSetup({
    ajaxComplete: function(xhr, textStatus) {
        if(xhr.status == 409){
            make_popup_box('',"refresh_confirm","Duplicate request received. Please refresh the page to proceed",{
                'ok':'Refresh',
                'title':""
            });
        }
        else if (xhr.status == 403){
            make_popup_box('',"refresh_confirm","You are not permitted to perform this action",{
                'ok':'Refresh',
                'title':""
            });
        }
        else if (200 == response.status){
            if (j('#session_fingerprint').length){
        //                j('#session_fingerprint').val(response.getHeader('session_fingerprint'));
        }
        }
    }
});
