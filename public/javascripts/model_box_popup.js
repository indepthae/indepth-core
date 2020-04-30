// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var tooltip_timer, delay = 1000, field_error = true;

function make_popup_box(elm, type, text, options)
{
    var defaults = {
        ok: 'OK',
        cancel: 'Cancel',
        submit: 'Submit',
        title: '',
        link: j(elm).attr('href'),
        field_name: 'field_name',
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
    if(j('#page-yield').length > 0){
        j('#page-yield').append(overlay);
        j('#page-yield').append(par_div);
        j('#popup_window').offset({
            left : (j('body').width() - j('#popup_window').width())/2
        });
    }else{
        j('#content').append(overlay);
        j('#content').append(par_div);
        j('#popup_window').offset({
            left : ((j('body').width() - j('#popup_window').width())/2)
        });
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
