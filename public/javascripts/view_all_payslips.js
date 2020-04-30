var payroll_group_id, start_date, end_date, data, translations, ind_earnings, ind_deductions;
var timer, pen_payslips, payslip_ids, slices, approved_ids, app_payslips, app_payslips_ids, success_count = 0, failed_count = 0;
var delay = 1000;
var chunk = [], finished = [], chunk_approve = [];
var send_flag = true;

initialize_variables = function(data, messages) {
    data = data;
    payroll_group_id = data['payroll_group_id'];
    start_date = data['start_date'];
    end_date = data['end_date'];
    finance = data['finance'],
    translations = messages;
    ind_earnings = data['ind_earnings'];
    ind_deductions = data['ind_deductions'];
}

filter_payslips = function() {
    new Ajax.Request('/employee_payslips/view_all_employee_payslip',{
        parameters: {
            id : payroll_group_id,
            start_date : start_date,
            end_date : end_date ,
            finance : finance,
            employees : j('#payslip_employees').val(),
            status : j('#payslip_status').val()
        },
        asynchronous:true,
        evalScripts:true,
        method:'post',
        processData: false,
        onLoading: function(){
            j('#loader').show();
        },
        onComplete:function(resp){
            if(finance)
            {
                if((j('#payslip_status').val() == 'pending') && (j('#pen_payslips').val().length>0))
                    j('#approve_all').show();
                else
                    j('#approve_all').hide();
                if((j('#payslip_status').val() == 'approved') && (j('#approved_payslips').val().length>0))
                    j('#revert_t_all').show();
                else
                    j('#revert_t_all').hide();
            }
            else
            {
                if((j('#payslip_status').val() == 'pending') && (j('#pen_payslips').val().length>0))
                    j('#revert_all').show();
                else
                    j('#revert_all').hide();
            }
            j('#loader').hide();
        }
    });
}
revert_individual_payslip = function() {
    message = translations['the_payslip_of'] + " <b>" + j(this).attr('emp_name') + "</b> " + translations['for_pay_period'] + " <b>" + translations['pay_period'] + "</b> " + translations['will_be_deleted']
    confirm_box("delete", this, message, send_revert_payslip_request);
}
approve_individual_payslip = function() {
    if(j(this).attr('approve') == "false")
    {
        message = translations['the_payslip_of'] + " <b>" + j(this).attr('emp_name') + "</b> " + translations['for_pay_period'] + " <b>" + translations['pay_period'] + "</b> " + translations['will_be_approved']
        confirm_box("approve", this, message, send_approve_payslip_request);
    }
    else
        build_failed_box('approve');
}
revert_transaction = function() {
    if(j(this).attr('archived') == "true")
        message = translations['archived_payslip_revert_message'] + " " + translations['the_payslip_of'] + " <b>" + j(this).attr('emp_name') + "</b> " + translations['for_pay_period'] + " <b>" + translations['pay_period'] + "</b> " + translations['will_be_deleted']
    else
        message = translations['the_payslip_of'] + " <b>" + j(this).attr('emp_name') + "</b> " + translations['for_pay_period'] + " <b>" + translations['pay_period'] + "</b> " + translations['will_be_reverted']
    confirm_box("revert", this, message, send_revert_transaction_payslip_request);
}
confirm_box = function(type, elm, message, yes_function){
    build_confirm_box(type, message);
    j('.confirm > #yes').click(function () {
        j(this).off('click');
        yes_function(elm);
        yes_function = function () {};
        hideLopModalBox();
    });
}
build_confirm_box = function(type, message){
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    par_div = j('#MB_window');
    frame = j('<div></div>', {
        'id' : 'modal_frame'
    });
    head = j('<div></div>', {
        'id' : 'MB_header_part',
        'class' : 'part'
    });
    header =j('<h4></h4>', {
        'text' : translations[type+'_payslip']
    });
    head.append(header);
    frame.append(head);
    content = j('<div></div>', {
        'id' : 'MB_content',
        'class' : 'part'
    });
    confirmation = j('<p></p>',{
        'id' : 'confirmation',
        'html' : message
    });
    content.append(confirmation);
    frame.append(content);
    footer = j('<div></div>', {
        'id' : 'MB_footer',
        'class' : 'part confirm'
    });
    ok = j('<div></div>', {
        'id' : 'yes',
        'class' : 'submit-button',
        'text' : translations[type+'_payslip']
    });
    cancel_frame = j('<div></div>', {
        'id' : 'no',
        'class' : 'submit-button',
        'text' : translations['cancel'],
        'onclick' : 'hideLopModalBox()'
    });
    footer.append(ok);
    footer.append(cancel_frame);
    frame.append(footer);
    par_div.append(frame);
    par_div.show();
    align_modal_box();
}
send_revert_payslip_request = function(elm) {
    new Ajax.Request('/employee_payslips/revert_employee_payslip',{
        parameters: {
            id : j(elm).attr('payslip_id'),
            from : 'view_all_employee_payslip'
        },
        asynchronous:true,
        evalScripts:true,
        method:'post',
        processData: false,
        onLoading: function(){
            j('#loader_' + j(elm).attr('payslip_id')).show();
            unbind_click();
        },
        onComplete:function(resp){
            j('#payslip_' + j(elm).attr('payslip_id')).addClass('disabled');
            j('#payslip_' + j(elm).attr('payslip_id') + ' .actions').text(translations['reverted']);
            j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children().first().children().attr('class', 'reverted symbol')
            j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children('.helper_info').remove();
            get_pending_payslips_id(j(elm).attr('payslip_id'));
            if((j('#pen_payslips').val().length == 0))
                j('#revert_all').hide();
            bind_click();
        }
    });
}
send_approve_payslip_request = function(elm) {
    new Ajax.Request('/finance/employee_payslip_approve',{
        parameters: {
            id : j(elm).attr('payslip_id'),
            from : 'all_payslips_finance'
        },
        asynchronous:true,
        evalScripts:true,
        method:'post',
        processData: false,
        onLoading: function(){
            j('#loader_' + j(elm).attr('payslip_id')).show();
            unbind_click();
        },
        onComplete:function(resp){
            j('#payslip_' + j(elm).attr('payslip_id') + ' .actions .approve').remove();
            j('#payslip_' + j(elm).attr('payslip_id') + ' .actions .reject').remove();
            revert = j('<div></div>', {
                'class' : 'revert_t',
                'payslip_id' : j(elm).attr('payslip_id'),
                'emp_name' : j(elm).attr('emp_name'),
                'archived': j(elm).attr('archived'),
                'text' : translations['revert_payslip']
            });
            j('#payslip_' + j(elm).attr('payslip_id') + ' .actions').prepend(revert);
            j('#payslip_' + j(elm).attr('payslip_id') + ' .actions #loader_' + j(elm).attr('payslip_id')).hide();
            j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children().first().children().attr('class', 'tick symbol')
            j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children('.helper_info').remove();
            get_pending_payslips_id(j(elm).attr('payslip_id'));
            add_approved_payslips_id(j(elm).attr('payslip_id'));
            if((j('#pen_payslips').val().length == 0))
                j('#approve_all').hide();
            if((j('#payslip_status').val() == 'approved') && (j('#approved_payslips').val().length>0))
                j('#revert_t_all').show();
            if(j('#payslip_status').children().length == 1)
            {
                j('#payslip_status').prepend('<option value="approved">'+ translations['approved'] +'</option>');
                j('#payslip_status').prepend('<option value="approved_and_pending">'+ translations['all'] +'</option>');
            }
            bind_click();
        }
    });
}
send_revert_transaction_payslip_request = function(elm){
    new Ajax.Request('/finance/payslip_revert_transaction',{
        parameters: {
            id : j(elm).attr('payslip_id'),
            from : 'all_payslips_finance'
        },
        asynchronous:true,
        evalScripts:true,
        method:'post',
        processData: false,
        onLoading: function(){
            j('#loader_' + j(elm).attr('payslip_id')).show();
            unbind_click();
        },
        onComplete:function(resp){
            if(j(elm).attr('archived') == "false")
            {
                j('#payslip_' + j(elm).attr('payslip_id') + ' .actions .revert_t').remove();
                approve = j('<div></div>', {
                    'class' : 'approve',
                    'payslip_id' : j(elm).attr('payslip_id'),
                    'emp_name' : j(elm).attr('emp_name'),
                    'archived': j(elm).attr('archived'),
                    'text' : translations['approve_payslip'],
                    'approve' : 'false'
                });
                reject = j('<div></div>', {
                    'class' : 'reject',
                    'payslip_id' : j(elm).attr('payslip_id'),
                    'text' : translations['reject_payslip'],
                    'reject' : 'false'
                });
                j('#payslip_' + j(elm).attr('payslip_id') + ' .actions').prepend(reject);
                j('#payslip_' + j(elm).attr('payslip_id') + ' .actions').prepend(approve);
                j('#payslip_' + j(elm).attr('payslip_id') + ' .actions #loader_' + j(elm).attr('payslip_id')).hide();
                j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children().first().children().attr('class', 'pending symbol')
                j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children('.helper_info').remove();
            }
            else
            {
                j('#payslip_' + j(elm).attr('payslip_id')).addClass('disabled');
                j('#payslip_' + j(elm).attr('payslip_id') + ' .actions').text(translations['reverted']);
                j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children().first().children().attr('class', 'reverted symbol')
                j('#payslip_' + j(elm).attr('payslip_id') + ' .status').children().children('.helper_info').remove();
            }
            add_pending_payslips_id(j(elm).attr('payslip_id'));
            get_approve_payslips_id(j(elm).attr('payslip_id'));
            if(j('#approved_payslips').val().length == 0)
                j('#revert_t_all').hide();
            if((j('#payslip_status').val() == 'pending') && (j('#pen_payslips').val().length>0))
                j('#approve_all').show();
            if(j('#payslip_status').children().length == 1)
            {
                j('#payslip_status').append('<option value="pending">'+ translations['pending'] +'</option>');
                j('#payslip_status').prepend('<option value="approved_and_pending">'+ translations['all'] +'</option>');
            }
            bind_click();
        }
    });
}

mouse_leave = function() {
    j(this).children('.helper_info').hide();
    j(this).parent().removeClass('hover_cell');
    clearTimeout(timer);
}

hide_earning_others = function() {
    payslip_id = j(this).attr('payslip_id');
    j('#ind_ear_'+payslip_id).hide();
    j(this).parent().removeClass('hover_cell');
    clearTimeout(timer);
}

hide_deduction_others = function() {
    payslip_id = j(this).attr('payslip_id');
    j('#ind_ded_'+payslip_id).hide();
    j(this).parent().removeClass('hover_cell');
    clearTimeout(timer);
}

hide_lop_tooltip = function() {
    payslip_id = j(this).attr('payslip_id');
    j('#lop_info_'+payslip_id).hide();
    clearTimeout(timer);
}

employee_name = function() {
    var elm = this;
    timer = setTimeout(function() {
        j(elm).parent().addClass('hover_cell');
        if(j(elm).children('.helper_info').length > 0)
            j(elm).children('.helper_info').show();
        else
            make_emp_name_tooltip(elm);
    }, delay);
}

status_info =function() {
    var elm = this;
    timer = setTimeout(function() {
        j(elm).parent().addClass('hover_cell');
        if(j(elm).children('.helper_info').length > 0)
            j(elm).children('.helper_info').show();
        else
            make_status_tooltip(elm);
    }, delay);
}
make_emp_name_tooltip = function(elm) {
    par_div = j('<div></div>', {
        'class' : 'helper_info status_tooltip',
        'html' : j(elm).children('.info_header').html()
    });
    j(elm).append(par_div);
}
make_status_tooltip = function(elm)  {
    if(j(elm).children('.info_header').children().attr('class') == "pending symbol")
        msg = translations['pending'];
    else if(j(elm).children('.info_header').children().attr('class') == "reverted symbol")
        msg = translations['reverted'];
    else if(j(elm).children('.info_header').children().attr('class') == "rejected symbol")
        msg = translations['rejected'];
    else
        msg = translations['approved'];
    par_div = j('<div></div>', {
        'class' : 'helper_info status_tooltip',
        'text' : msg
    });
    j(elm).append(par_div);
}

align_tooltip = function(elm, id) {
    payslip_id = j(elm).attr('payslip_id');
    tooltip = j('#' + id + '_'+payslip_id);
    tooltip_width = tooltip.outerWidth();
    left_pos = j(elm).parent().position().left;
    outer_width = j('.outer').outerWidth();
    elm_outer_width = j(elm).parent().outerWidth();
    right_pos = left_pos + elm_outer_width;
    third_child_left = j('tr.tr-head td:nth-child(2)').position().left + j('tr.tr-head td:nth-child(2)').outerWidth();

    if(third_child_left < (right_pos - tooltip_width))
    {
        if(right_pos < outer_width)
        {
            tooltip.css({
                'left' : '',
                'right': outer_width - right_pos
            });
            j("#dynamic").text(".helper_info:before{left : auto; right : "+ ((elm_outer_width/2) - 11) +"px} .helper_info:after{left : auto; right : "+ ((elm_outer_width/2) - 11) +"px;}");
        }
        else
        {
            tooltip.css({
                'left' : '',
                'right': 0
            });
            j("#dynamic").text(".helper_info:before{left : auto; right : "+ (((outer_width - left_pos)/2) - 11) +"px} .helper_info:after{left : auto; right : "+ (((outer_width - left_pos)/2) - 11) +"px;}");
        }
    }
    else
    {
        if(third_child_left < left_pos)
        {
            tooltip.css({
                'right' : '',
                'left': left_pos
            });
            j("#dynamic").text(".helper_info:before{right : auto; left : "+ (elm_outer_width/2) +"px} .helper_info:after{right : auto; left : "+ (elm_outer_width/2) +"px;}");
        }
        else
        {
            tooltip.css({
                'right' : '',
                'left': third_child_left
            });
            j("#dynamic").text(".helper_info:before{left:"+ ((right_pos - third_child_left)/2) +"px} .helper_info:after{left:"+ ((right_pos - third_child_left)/2) +"px;}");
        }
    }
    top_pos = j(elm).position().top;
    elm_outer_height = j(elm).outerHeight();
    tooltip.css({
        'top' : (top_pos + elm_outer_height) + 'px'
    });
    footer_top = j('#footer').offset().top;
    tooltip_top = tooltip.offset().top
    tooltip_height = tooltip.outerHeight();
    if(footer_top < (tooltip_top + tooltip_height))
    {
        tooltip.addClass('upside_down');
        tooltip.css({
            'top' : (top_pos - tooltip_height) + 'px'
        });
    }
    else
        tooltip.removeClass('upside_down');
            
    outer_height = j('.outer').outerHeight();
    
}

align_tooltip_rtl = function(elm, id) {
    payslip_id = j(elm).attr('payslip_id');
    tooltip = j('#' + id + '_'+payslip_id);
    tooltip_width = tooltip.outerWidth();
    left_pos = j(elm).parent().position().left;
    outer_width = j('.outer').outerWidth();
    elm_outer_width = j(elm).parent().outerWidth();
    right_pos = left_pos + elm_outer_width;
    third_child_left = j('tr.tr-head td:nth-child(2)').position().left;
    fixed_cell_width = j('tr.tr-head td:nth-child(1)').outerWidth()+j('tr.tr-head td:nth-child(2)').outerWidth();
    if(third_child_left > (left_pos + tooltip_width))
    {

        if(left_pos > 0)
        {
            tooltip.css({
                'left' : left_pos,
                'right': ''
            });
            j("#dynamic").text(".helper_info:before{right : auto; left : "+ ((elm_outer_width/2) - 11) +"px} .helper_info:after{right : auto; left : "+ ((elm_outer_width/2) - 11) +"px;}");
        }
        else
        {
            tooltip.css({
                'left' : 0,
                'right': ''
            });
            j("#dynamic").text(".helper_info:before{right : auto; left : "+ ((right_pos/2) - 11) +"px} .helper_info:after{right : auto; left : "+ ((right_pos/2) - 11) +"px;}");
        }
    }
    else
    {
        if(third_child_left > right_pos)
        {
            tooltip.css({
                'right' : fixed_cell_width + (third_child_left - right_pos),
                'left': ''
            });
            j("#dynamic").text(".helper_info:before{left : auto; right : "+ (elm_outer_width/2) +"px} .helper_info:after{left : auto; right : "+ (elm_outer_width/2) +"px;}");
        }
        else
        {
            tooltip.css({
                'right' : fixed_cell_width,
                'left': ''
            });
            j("#dynamic").text(".helper_info:before{right:"+ ((third_child_left - left_pos)/2) +"px} .helper_info:after{right:"+ ((third_child_left - left_pos)/2) +"px;}");
        }
    }
    top_pos = j(elm).position().top;
    elm_outer_height = j(elm).outerHeight();
    tooltip.css({
        'top' : (top_pos + elm_outer_height) + 'px'
    });
    footer_top = j('#footer').offset().top;
    tooltip_top = tooltip.offset().top
    tooltip_height = tooltip.outerHeight();
    if(footer_top < (tooltip_top + tooltip_height))
    {
        tooltip.addClass('upside_down');
        tooltip.css({
            'top' : (top_pos - tooltip_height) + 'px'
        });
    }
    else
        tooltip.removeClass('upside_down');

    outer_height = j('.outer').outerHeight();

}

make_tooltip = function(elm, categories, id)  {
    par_div = j('<div></div>', {
        'class' : 'helper_info',
        'id' : id + '_' + j(elm).attr('payslip_id')
    });
    table = j('<table></table>', {
        'class' : 'additional_cat'
    });
    j.each(categories, function(name, amount){
        row = j('<tr></tr>');
        cell1 = j('<td></td>', {
            'class' : 'add_name',
            'text' : name
        });
        cell2 = j('<td></td>', {
            'class' : 'add_amount',
            'text' : amount
        });
        row.append(cell1);
        row.append(cell2);
        table.append(row);
    });
    par_div.append(table);
    j('.outer').append(par_div);
}

individual_deductions = function() {
    var elm = this;
    timer = setTimeout(function() {
        j(elm).parent().addClass('hover_cell');
        payslip_id = j(elm).attr('payslip_id');
        deductions = ind_deductions[payslip_id];
        if(j('#ind_ded_'+payslip_id).length > 0)
            j('#ind_ded_'+payslip_id).show();
        else
            make_tooltip(elm, deductions, 'ind_ded');
        if(j('html').attr('dir') == 'ltr')
            align_tooltip(elm, 'ind_ded');
        else
            align_tooltip_rtl(elm, 'ind_ded');
    }, delay);
}

individual_earnings = function() {
    var elm = this;
    timer = setTimeout(function() {
        j(elm).parent().addClass('hover_cell');
        payslip_id = j(elm).attr('payslip_id');
        earnings = ind_earnings[payslip_id];
        if(j('#ind_ear_'+payslip_id).length > 0)
            j('#ind_ear_'+payslip_id).show();
        else
            make_tooltip(elm, earnings, 'ind_ear');
        if(j('html').attr('dir') == 'ltr')
            align_tooltip(elm, 'ind_ear');
        else
            align_tooltip_rtl(elm, 'ind_ear');
    }, delay);
}

lop_tooltip = function(){
    var elm = this;
    timer = setTimeout(function() {
        payslip_id = j(elm).attr('payslip_id');
        if(j('#lop_info_'+payslip_id).length > 0)
            j('#lop_info_'+payslip_id).show();
        else{
            par_div = j('<div></div>', {
                'class' : 'helper_info lop_tooltip',
                'id' : 'lop_info_' + payslip_id,
                'text' : translations['lop_info']
            });
            j('.outer').append(par_div);
        }
        if(j('html').attr('dir') == 'ltr')
            align_tooltip(elm, 'lop_info');
        else
            align_tooltip_rtl(elm, 'lop_info');
    }, delay); 
}

get_pending_payslips_id = function(id) {
    pen_payslips = j('#pen_payslips').val().split(',');
    var i = pen_payslips.indexOf(id);
    if(i != -1) {
        pen_payslips.splice(i, 1);
    }
    j('#pen_payslips').val(pen_payslips.join(","));
}

get_approve_payslips_id = function(id) {
    app_payslips = j('#approved_payslips').val().split(',');
    var i = app_payslips.indexOf(id);
    if(i != -1) {
        app_payslips.splice(i, 1);
    }
    j('#approved_payslips').val(app_payslips.join(","));
}

add_pending_payslips_id = function(id) {
    pen_payslips_ids = j('#pen_payslips').val()
    if(pen_payslips_ids){
        pen_payslips = j('#pen_payslips').val().split(',');
        pen_payslips.push(id);
        j('#pen_payslips').val(pen_payslips.join(","));
    }
    else
        j('#pen_payslips').val(id);
}

add_approved_payslips_id = function(id) {
    app_payslips_ids = j('#approved_payslips').val()
    if(app_payslips_ids){
        app_payslips = j('#approved_payslips').val().split(',');
        app_payslips.push(id);
        j('#approved_payslips').val(app_payslips.join(","));
    }
    else
        j('#approved_payslips').val(id);
}

revert_all = function()
{
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    build_modal_box('revert');
}
approve_all = function()
{
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    build_modal_box('approve');
}
revert_transaction_all = function()
{
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    build_modal_box('transaction');
}
showLopModalBox = function() {
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    j('#MB_window').show();
}
hideLopModalBox = function() {
    j('#MB_overlay').hide();
    j('#modal_frame').remove();
    j('#MB_window').hide();
}
build_modal_box = function(action) {
    par_div = j('#MB_window');
    frame = j('<div></div>', {
        'id' : 'modal_frame'
    });
    head = j('<div></div>', {
        'id' : 'MB_header_part',
        'class' : 'part'
    });
    header =j('<h4></h4>', {
        'text' : translations[action+'_payslips']
    });
    head.append(header);
    frame.append(head);
    content = j('<div></div>', {
        'id' : 'MB_content',
        'class' : 'part'
    });
    confirmation = j('<p></p>',{
        'id' : 'confirmation',
        'html' : translations[action+'_all_confirmation']
    });
    content.append(confirmation);
    frame.append(content);
    footer = j('<div></div>', {
        'id' : 'MB_footer',
        'class' : 'part'
    });
    ok = j('<div></div>', {
        'id' : 'ok_button',
        'class' : 'submit-button',
        'text' : translations[action+'_payslips'],
        'onclick' : "payslip_actions('"+action+"')"
    });
    cancel_frame = j('<div></div>', {
        'id' : 'cancel_frame',
        'class' : 'submit-button',
        'text' : translations['cancel'],
        'onclick' : 'hideLopModalBox()'
    });
    footer.append(ok);
    footer.append(cancel_frame);
    frame.append(footer);
    par_div.append(frame);
    par_div.show();
    align_modal_box();
}
payslip_actions = function(action) {
    content = j('#modal_frame #MB_content')
    footer = j('#modal_frame #MB_footer');
    content.html('');
    msg1 = j('<p></p>', {
        'html' : translations[action+'_message']
    });
    msg2 = j('<p></p>', {
        'html' : translations['date_range']
    });
    msg3 = j('<p></p>', {
        'id' : 'loader_sec'
    });
    msg3.append('<img align="absmiddle" alt="Loader" border="0" id="loader1" src="/images/loader.gif">');
    msg4 = j('<p></p>', {
        'html' : translations[action+'_status'],
        'id' : 'status'
    });
    msg6 = j('<p></p>', {
        'html' : translations[action+'_failed_status'],
        'class' : 'failed_status',
        'id' : 'status',
        'style' : 'display : none'
    });
    msg5 = j('<p></p>', {
        'text' : translations['warning'],
        'id' : 'warning'
    });
    content.append(msg1);
    content.append(msg2);
    content.append(msg3);
    content.append(msg4);
    content.append(msg6);
    content.append(msg5);
    footer.html('');
    cancel_frame = j('<a></a>', {
        'class' : 'submit-button',
        'text' : translations['cancel'],
        'href' : window.location.href
    });
    footer.append(cancel_frame);
    if(action == 'transaction')
    {
        if(j('#approved_payslips').val())
            payslip_ids = j('#approved_payslips').val().split(',');
        else
            payslip_ids = []
        j('#total').text(payslip_ids.length);
    }
    else
    {
        if(j('#pen_payslips').val())
            payslip_ids = j('#pen_payslips').val().split(',');
        else
            payslip_ids = []
        j('#total').text(payslip_ids.length);
    }
    if(action == 'transaction')
        chunk_approve_array();
    else
        chunk_array();
    if(action == 'revert')
        send_request();
    else if(action == 'approve')
        send_approve_request();
    else
        send_revert_transaction_request();
}
cancel_request = function() {
    send_flag = false;
}

changing_status = function(){
    j('#MB_content #loader_sec').html('<span class="tick symbol"></span>');
    j('#MB_footer a').text(translations['ok']);
    j('#MB_content p#warning').hide();
}

send_request = function() {
    if((chunk.length > 0) && send_flag)
    {
        slices = chunk.shift();
        new Ajax.Request('/employee_payslips/revert_all_payslips',{
            parameters: {
                payslip_ids : slices.join(','),
                start_date : start_date,
                end_date :  end_date,
                payroll_group_id : payroll_group_id
            },
            asynchronous:true,
            evalScripts:true,
            method:'post',
            processData: false,
            onComplete:function(resp){
                delete_count = parseInt(resp.responseText);
                slice_count = slices.length;
                success_count += delete_count;
                failed_count += (slice_count - delete_count);
                if(failed_count > 0)
                {
                    j('.failed_status').show();
                    j('#failed_count').html(failed_count);
                }
                j.merge(finished, slices);
                j('#count').html(success_count);
                send_request();
            }
        });
    }
    else{
        if(chunk.length == 0)
        {
            j('#MB_content p:first').html(translations['revert_complete_message']);
            changing_status();
        }
    }
}
send_approve_request = function() {
    if((chunk.length > 0) && send_flag)
    {
        slices = chunk.shift();
        new Ajax.Request('/finance/employee_payslip_approve',{
            parameters: {
                payslip_ids : slices.join(','),
                from : 'all_payslips_finance'
            },
            asynchronous:true,
            evalScripts:true,
            method:'post',
            processData: false,
            onComplete:function(resp){
                app_count = parseInt(resp.responseText);
                slice_count = slices.length;
                success_count += app_count;
                failed_count += (slice_count - app_count);
                j.merge(finished, slices);
                j('#count').html(success_count);
                if(failed_count > 0)
                {
                    j('.failed_status').show();
                    j('#failed_count').html(failed_count);
                }
                send_approve_request();
            }
        });
    }
    else{
        if(chunk.length == 0)
        {
            j('#MB_content p:first').html(translations['approve_complete_message']);
            changing_status();
        }
    }
}
send_revert_transaction_request = function() {
    if((chunk_approve.length > 0) && send_flag)
    {
        slices = chunk_approve.shift();
        new Ajax.Request('/finance/payslip_revert_transaction',{
            parameters: {
                payslip_ids : slices.join(','),
                from : 'all_payslips_finance'
            },
            asynchronous:true,
            evalScripts:true,
            method:'post',
            processData: false,
            onComplete:function(resp){
                revert_count = parseInt(resp.responseText);
                slice_count = slices.length;
                success_count += revert_count;
                failed_count += (slice_count - revert_count);
                j('#count').html(success_count);
                if(failed_count > 0)
                {
                    j('.failed_status').show();
                    j('#failed_count').html(failed_count);
                }
                j.merge(finished, slices);
                j('#count').html(success_count);
                send_revert_transaction_request();
            }
        });
    }
    else{
        if(chunk_approve.length == 0)
        {
            j('#MB_content p:first').html(translations['transaction_complete_message']);
            changing_status();
        }
    }
}

reject_individual_payslip = function(){
    elm = this;
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    j('#MB_window').show();
    par_div = j('#MB_window');
    frame = j('<div></div>', {
        'id' : 'modal_frame'
    });
    head = j('<div></div>', {
        'id' : 'MB_header_part',
        'class' : 'part'
    });
    header =j('<h4></h4>', {
        'text' : translations['reject_employee_payslips']
    });
    head.append(header);
    frame.append(head);
    content = j('<div></div>', {
        'id' : 'MB_content',
        'class' : 'part'
    });
    label = j('<label></label>',{
        'id' : 'reason',
        'text' : translations['reason']
    });
    content.append(label);
    text_input = j('<div></div>',{
        'class' : 'text-input-bg'
    });
    input = j('<input></input>',{
        'size' : 30,
        'type' : 'text',
        'id' : 'payslip_reason'
    });
    text_input.append(input);
    content.append(text_input);
    frame.append(content);
    footer = j('<div></div>', {
        'id' : 'MB_footer',
        'class' : 'part reject_sec'
    });
    ok = j('<div></div>', {
        'id' : 'ok_button',
        'class' : 'submit-button',
        'text' : translations['reject_payslip'],
        'onclick' : 'reject_payslips('+ j(elm).attr('payslip_id') +')'
    });
    cancel_frame = j('<div></div>', {
        'id' : 'cancel_frame',
        'class' : 'submit-button',
        'text' : translations['cancel'],
        'onclick' : 'hideLopModalBox()'
    });
    footer.append(ok);
    footer.append(cancel_frame);
    frame.append(footer);
    par_div.append(frame);
    par_div.show();
    align_modal_box();
}

reject_payslips = function(id){
    if(j('#payslip_reason').val().length > 0){
        j('#ok_button').attr('onclick', '')
        new Ajax.Request('/finance/employee_payslip_reject',{
            parameters: {
                id : id,
                reason : j('#payslip_reason').val(),
                from : 'all_payslips_finance'
            },
            asynchronous:true,
            evalScripts:true,
            method:'post',
            processData: false,
            onComplete:function(resp){
                j('#payslip_' + id).addClass('disabled');
                j('#payslip_' + id + ' .actions .approve').remove();
                j('#payslip_' + id + ' .actions .reject').remove();
                j('#payslip_' + id + ' .actions #loader_' + id).hide();
                j('#payslip_' + id + ' .status').children().children().first().children().attr('class', 'rejected symbol')
                j('#payslip_' + id + ' .status').children().children('.helper_info').remove();
                get_pending_payslips_id(id);
                hideLopModalBox()
            }
        });
    }
    else
        make_error_message(translations['reject_error_message'])
}
function make_error_message(message){
    j('#MB_content .wrapper').remove();
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
    j('#MB_content').append(wrapper);
}
chunk_array = function() {
    if(j('#pen_payslips').val())
    {
        payslip_ids = j('#pen_payslips').val().split(',');
        while (payslip_ids.length > 0) {
            chunk.push(payslip_ids.splice(0,10));
        }
    }
}
chunk_approve_array = function() {
    if(j('#approved_payslips').val())
    {
        approved_ids = j('#approved_payslips').val().split(',');
        while (approved_ids.length > 0) {
            chunk_approve.push(approved_ids.splice(0,10));
        }
    }
}
unbind_click = function(){
    j(".revert").unbind("click");
    j(".approve").unbind("click");
    j(".reject").unbind("click");
    j(".revert_t").unbind("click");
}
bind_click = function(){
    j(".revert").click(revert_individual_payslip);
    j(".approve").click(approve_individual_payslip);
    j(".reject").click(reject_individual_payslip);
    j(".revert_t").click(revert_transaction);
}
build_failed_box = function(action) {
    j('#MB_overlay').show();
    j('#MB_overlay').css('opacity',0.75);
    par_div = j('#MB_window');
    frame = j('<div></div>', {
        'id' : 'modal_frame'
    });
    head = j('<div></div>', {
        'id' : 'MB_header_part',
        'class' : 'part'
    });
    header =j('<h4></h4>', {
        'text' : translations[action +'_payslip']
    });
    head.append(header);
    frame.append(head);
    content = j('<div></div>', {
        'id' : 'MB_content',
        'class' : 'part'
    });
    confirmation = j('<p></p>',{
        'id' : 'confirmation',
        'text' : translations[action + '_failed_message']
    });
    content.append(confirmation);
    frame.append(content);
    footer = j('<div></div>', {
        'id' : 'MB_footer',
        'class' : 'part'
    });
    ok = j('<div></div>', {
        'id' : 'ok_button',
        'class' : 'submit-button',
        'text' : translations['ok'],
        'onclick' : "hideLopModalBox()"
    });
    footer.append(ok);
    frame.append(footer);
    par_div.append(frame);
    par_div.show();
    align_modal_box();
}
align_modal_box = function(){
    if(j('html').attr('dir') == 'ltr')
        j('#MB_window').css({
            left : (j('body').width() - j('#MB_window').width())/2
        });
    else
        j('#MB_window').css({
            right : (j('body').width() - j('#MB_window').width())/2
        });
}