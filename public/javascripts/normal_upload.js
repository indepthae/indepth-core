function reset_values()
{
    var default_val = j('.field1').attr('default');
    j('.field1').val(default_val);
    j('.paper').val('');
}
function paperclip_file_upload(e, el)
{
    var e_parent = j(el).parents('.paperclip_field');
    var el_id = el.id;
    var outer_field = j(e_parent).find('#field_' + el_id);
    var inner_field = j(e_parent).find('#' + el_id);
    j(outer_field).val(el.files[0].name.truncate(15));
    j(outer_field).attr("title", el.files[0].name);
    j(el).attr("title", el.files[0].name);
}
PaperclipHelp = function () {
    this.attachment_set = [];
    this.index = 0;
    this.paperclip_file_upload_test1 = function (e, el, unique_id) {
        var attachment_set = this.attachment_set;
        var index = this.index;
        var remove_tag = j(el).parent().next(".remove_attachment");
        parent_div = j(el).parent().parent().parent();
        parent_div.next('#attachment-error').css("display", "none");

        for (var i = 0; i < el.files.length; i++) {
            if (el.files && el.files[i]) {
                scroll_div = j("#conversations-scroll").height();                
                att_err_div = j("#attachment-error").height();
                if ((j.inArray(el.files[i].type, valid_attachments) == -1) || (el.files[i].size > 5242880)) {
                    not_valid_type = true;
                    parent_div.next('#attachment-error').css("display", "inline-block");
                    parent_div.next('#attachment-error').children(".error-msg").html("File Size/format not supported");                    
                } else {
                    if (attachment_set.length < 5) {  
                        j("#conversations-scroll").css("height", scroll_div +"px");
                        attachment_set[index] = el.files[i];                       
                        var file_name = attachment_set[index].name;
                        if (file_name.length > 15) {
                            file_name = file_name.substring(0, 15) + '...';
                        }
                        att_div = j(el).parent().parent().parent().find("#selected_attachments");
                        att_div.append('<div class ="text-input-bg" id="attachment-style"><div id="preview' + index + '" class="attachment_preview">' + file_name + '</div></div>');
                        
                        remove_tag.clone().appendTo(parent_div.find("#preview" + index).parent());

                        parent_div.find("#preview" + index).next().css("display", "block");
                        parent_div.find("#preview" + index).next().find(".remove_attachment_tag").attr("id", "tag" + index).attr("data-value", index);
                        att_div =  parent_div.find("#attachment-style").height();  
                        parent_div.next().find("input[type=submit]").removeAttr("disabled");
                        if(unique_id == 'reply_message'){
                         j("#conversations-scroll").css("height", scroll_div - att_div + "px");
                         file_uploaded();
                        }
                     index++;
                    } else {
                        parent_div.next('#attachment-error').css("display", "inline-block");
                        parent_div.next('#attachment-error').children(".error-msg").html("Can upload upto 5 images");
                    }
                }
            }
        }       
        this.attachment_set = attachment_set;
        this.index = index;
    }
    this.remove_element = function (elem,unique_id) {
        var attachment_set = this.attachment_set;
        var index = this.index;
        var id = j(elem).attr("data-value");
        reset_data_value(attachment_set, id);
        j("#deletepreview").closest(".text-input-bg").remove();
        att_div = j("#attachment-style").height();  
        scroll_div = j("#conversations-scroll").height();
        if(unique_id == 'reply_message'){
        j("#conversations-scroll").css("height", scroll_div + att_div + "px");
        }
        attachment_set = remove_file(attachment_set, id);
        this.attachment_set = attachment_set;
        index--;
        this.index = index;             
         if (this.attachment_set.length == 0) {
          j('#attachment-error').css("display", "none");   
          j("#conversations-scroll").css("height", "494px");
        }
    }
}
function remove_file(files, id) {
    var new_set = [];
    for (var i = 0; i < files.length; i++) {
        if (i != id) {
            new_set.push(files[i]);
        }
    }
    return new_set;
}
function reset_data_value(attachment_set, id) {
    var k = 0;
    for (var i = 0; i < attachment_set.length; i++) {
        if (i != id) {
            //j("#tag"+i).data("value",k);
            j("#tag" + i).attr("data-value", k);
            j(("#preview" + i)).attr("id", "preview" + k);
            j("#tag" + i).attr("id", "tag" + k);
            k++;
        } else {
            j(("#preview" + i)).attr("id", "deletepreview");
            j("#tag" + i).attr("id", "stubtag");
        }
    }
}


j(document).ready(function () {
    reset_values();
//j('input[type=file]').on('change', (function (e){}));
});