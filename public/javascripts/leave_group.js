var data, translations;
var chunk = [], set = {}, send_flag = true, success_count = 0, failed_count = 0, finished = [], total = 0;
function initialize_variables(group_data, messages) {
    data = group_data;
    translations = messages;
    leave_group_id = group_data.leave_group_id;
}
function showOverlay() {
    j('#loading').show();
}

function drawTable(data) {
    section = j('<div></div', {class: "container"});
    table = j('<table></table', {'width': '100%', 'cellpadding': 1, 'cellspacing': 1});
    thead = j('<thead></thead');
    table_head = j('<tr></tr>', {'class': "header"});
    json_data.header.each(function (h) {
        if (h == "check")
        {
            cell = j('<th></th>', {'class': 'check_all'});
            input = j('<input></input>', {'type': "checkbox", 'class': "select_all", 'onclick': "checkAll()", 'selected': json_data.thead[h]});
            cell.append(input);
        } else {
            cell = j('<th></th>', {'class': h});
            div_text = j('<div></div', {'text': json_data.thead[h]});
            cell.append(div_text);
        }
        table_head.append(cell)
    });
    thead.append(table_head);
    table.append(thead);
    if (Object.keys(json_data.tbody).length > 0) {
        j.each(json_data.tbody, function (id, key) {
            table_row = j('<tr></tr>');
            json_data.header.each(function (h) {
                if (h == "check") {
                    cell = j('<td></td>', {'class': 'check_all'});
                    input = j('<input></input>', {'type': "checkbox", 'class': "select_emp", 'onclick': "selectLeaveType(); updateValues(this)", 'selected': key[h], 'id': id});
                    cell.append(input);
                } else
                    cell = j('<td></td>', {'html': key[h], 'class': h});
                table_row.append(cell);
            });
            table.append(table_row);
        });
    } else {
        table_row = j('<tr></tr>');
        cell = j('<td></td>', {'html': translations.nothing_to_list, 'colspan': 5});
        table_row.append(cell);
        table.append(table_row);
    }
    section.append(table);
    j('.employees_table').append(section);
    if (Object.keys(json_data.tbody).length == 0)
        j('.select_all').hide();
}

function hideOverlay() {
    j('#loading').hide();
    j('#employees_form').show();
}

function checkAll()
{
    if (j('.select_all').prop('checked') == true)
    {
        j('.select_emp').prop('checked', true);
        j.each(changed_data.tbody, function (id, key) {
            key.check = true
        });
        selectLeaveType();
    } else {
        j('.select_emp').prop('checked', false);
        j.each(changed_data.tbody, function (id, key) {
            key.check = false
        })
        selectLeaveType();
    }
}

function selectLeaveType()
{
    if (j(".select_emp:checked").length == 0) {
        j('#count_0').show();
        j('#count_1, #count_2').hide();
    } else if (j(".select_emp:checked").length == 1) {
        j('#count_1').show();
        j('#count_0, #count_2').hide();
    } else {
        j('#count_2').show();
        j('#count_0, #count_1').hide();
        j('#status span').html(j(".select_emp:checked").length);
    }
    if (j(".select_emp:checked").length > 0)
        j('.wrapper').hide()
    allLeaves();
}

function updateValues(elm) {
    if (j(elm).prop('checked') == true)
        changed_data.tbody[j(elm).attr("id")].check = true;
    else
        changed_data.tbody[j(elm).attr("id")].check = false;
}

function allLeaves()
{
    if (j(".select_emp").not(":checked").length > 0)
        j('.select_all').prop("checked", false);
    else
        j('.select_all').prop("checked", true);
}

function chunkData(data) {
    i = 1;
    set = {}
    j.each(data, function (key, val) {
        if (val.check) {
            if (i > 50)
            {
                i = 1
                chunk.push(set);
                set = {}
            }
            set[key] = val
            i++;
        }
    });
    if (Object.keys(set).length > 0)
        chunk.push(set);
}
function confirmationBox() {
    total = 0;
    j.each(changed_data.tbody, function (key, val) {
        if (val.check)
            total++;
    });
    if (total > 0) {
        build_modal_box({'title': translations.confirmation_title, 'popup_class': 'confirmation'});
        j(window).scrollTop(0);
        content = j('<p></p>', {'html': translations.confirmation_message, 'id': 'confirmation_msg'});
        content1 = j('<div></div>', {'html': translations.credit_label_value, 'id': 'credit_label_value'});
        content2 = j('<p></p>', {'html': translations.confirmation_message_for_credit, 'id': 'msg_for_credit'});
        input = j('<input></input>', {'type': "checkbox", 'id': "update_credit", 'checked': false, 'name': "update_credit", 'class': "credit_update"});
        j('#popup_content').append(content);
        if (data.config == 1) {
            j('#popup_content').append(content1);
            j('#popup_content').append(input);
            j('#popup_content').append(content2);
        }
        save = j('<div></div>', {
            'id': 'ok_button',
            'class': 'submit-button',
            'text': translations.save,
            'onclick': "save_employees()"
        });
        cancel_frame = j('<div></div>', {
            'id': 'cancel_frame',
            'class': 'submit-button',
            'text': translations.cancel,
            'onclick': 'remove_popup_box()'
        });
        j('#popup_footer').append(save);
        j('#popup_footer').append(cancel_frame);
        j('#popup_box_overlay').click(remove_popup_box);
    } else
        j('.wrapper').show()
}
function cancel_request() {
    send_flag = false;
    window.location = (window.location.origin + "/leave_groups/" + leave_group_id);
}
function check_credit_update() {
    if (j('#update_credit').prop('checked') == true) {
        update_credit = 1
    }
    else {
        update_credit = 0
    }
}

function save_employees() {
    content = j('#popup_content');
    check_credit_update();
    footer = j('#popup_footer');
    content.html('');
    msg1 = j('<p></p>', {'html': translations.message1});
    msg2 = j('<p></p>', {'id': 'loader_sec'});
    msg2.append('<img align="absmiddle" alt="Loader" border="0" id="loader2" src="/images/loader.gif">');
    msg3 = j('<p></p>', {
        'html': translations.adding_status,
        'id': 'status'
    });
    msg4 = j('<p></p>', {
        'html': translations.adding_failed_status,
        'class': 'failed_status',
        'id': 'status',
        'style': 'display : none'
    });
    msg5 = j('<p></p>', {
        'text': translations.warning,
        'id': 'warning'
    });
    content.append(msg1);
    content.append(msg2);
    content.append(msg3);
    content.append(msg4);
    content.append(msg5);
    footer.html('');
    cancel_frame = j('<a></a>', {
        'class': 'submit-button',
        'text': translations.cancel,
        'href': "#",
        'onclick': "cancel_request()"
    });
    footer.append(cancel_frame);
    j('#popup_content #total').html(total);
    chunkData(changed_data.tbody);
    j('#popup_box_overlay').unbind('click');
    j('#popup_box_overlay').click(cancel_request);
    j('#MB_close').attr('onclick', "cancel_request()")
    send_request(update_credit);
}

function changing_status() {
    j('#popup_content p:first').html(translations.complete_message);
    j('#popup_content #loader_sec').html('<span class="tick symbol"></span>');
    j('#popup_footer a').text(translations.ok);
    j('#popup_content p#warning').hide();
}

function send_request() {
    if ((chunk.length > 0) && send_flag)
    {
        slices = chunk.shift();
        new Ajax.Request('/leave_groups/save_employees', {
            parameters: {
                update_credit: update_credit,
                json_data: Object.toJSON(slices),
                id: leave_group_id
            },
            asynchronous: true,
            evalScripts: true,
            method: 'post',
            processData: false,
            onComplete: function (resp) {
                count = parseInt(resp.responseText);
                slice_count = Object.keys(slices).length;
                success_count += count;
                failed_count += (slice_count - count);
                if (failed_count > 0)
                {
                    j('#popup_content .failed_status').show();
                    j('#popup_content #failed_count').html(failed_count);
                }
                j.merge(finished, slices);
                j('#popup_content #count').html(success_count);
                send_request();
            }
        });
    } else {
        if (chunk.length == 0)
            changing_status();
    }
}
