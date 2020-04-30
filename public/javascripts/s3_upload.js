function reset_values()
{
    var default_val = j('.field1').attr('default');
    j('.field1').val(default_val);
    j('.paper').val('');
}


PaperclipHelp = function () {
    var obj = this;
    this.attachment_set = [];
    this.index = 0;
    this.id_arr = [];
    this.new_id_arr = [];
    this.count = 0;
    this.load_index = 0;
    this.pgb = [];
    this.pgb_in = [];
    this.pgb_out = [];
    this.progress_index = 0;
    this.label_text = [];
    this.remove_field = [];
    this.paperclip_file_upload_test1 = function (e, el, u_id) {
        var no_file_chosen_label = 'No file selected';
        var el_id = el.id;
        var file_value = el;
        var xhr_arr = [];
        var str = [];
        var pgb = this.pgb;
        var pgb_in = this.pgb_in;
        var pgb_out = this.pgb_out;
        var label_text = this.label_text;
        var remove_field = this.remove_field;
        var upload_file_name = [];
        var upload_files = [];
        var error_text = [];

        var attachment_set = this.attachment_set;
        var index = this.index;
        var id_arr = this.id_arr;
        var new_id_arr = this.new_id_arr;
        var count = this.count;
        var load_index = this.load_index;
        var progress_index = this.progress_index;
        var paperclip_field_div = el.closest(".paperclip_field");
        var style = el.closest('.style');
        parent_div = j(el).parent().parent().parent()
        parent_div.next('#attachment-error').css("display", "none");

        for (var i = 0; i < el.files.length; i++) {
            if (el.files && el.files[i]) {
                scroll_div = j("#conversations-scroll").height();
                att_div = j(".paperclip_field").height();
                att_err_div = j("#attachment-error").height();
                if (attachment_set.length < 5) {
                    if ((j.inArray(el.files[i].type, valid_attachments) != -1) && (el.files[i].size <= 5242880)) {
                        j("#conversations-scroll").css("height", scroll_div + "px");
                        attachment_set[index] = el.files[i];
                        var pp_field = paperclip_field_div.cloneNode(true);
                        pp_field.setAttribute("id", "pp" + index);
                        j(el).parent().parent().parent().find(".selected_attachments").append(pp_field);
                        if (u_id == "reply_message") {
                            j("#conversations-scroll").css("height", scroll_div - att_div + "px");
                        }
                        var elm_id = el_id.split("attachment").join("").match(/\d+/g).last();
                        var pos = el_id.lastIndexOf(elm_id);
                        var d = new Date().getTime();
                        var new_id = el_id.slice(0, pos) + el_id.slice(pos).replace(elm_id, d);

                        parent_div.find("#pp" + index).addClass("attachment-clip");
                        parent_div.find("#pp" + index).find(".field1").attr("id", "field_" + new_id).attr("style", "display:inline-block");
                        parent_div.find("#pp" + index).find(".pgbar").attr("id", "progressbar_" + new_id);
                        parent_div.find("#pp" + index).find(".outpg").attr("id", "progressbarout_" + new_id);
                        parent_div.find("#pp" + index).find(".pg").attr("id", "progressbarin_" + new_id);
                        parent_div.find("#pp" + index).find("#key_" + el_id).attr("id", "key_" + new_id).attr("name", "key_" + new_id);
                        parent_div.find("#pp" + index).find("#AWSAccessKeyId_" + el_id).attr("id", "AWSAccessKeyId_" + new_id).attr("name", "AWSAccessKeyId_" + new_id);
                        parent_div.find("#pp" + index).find("#acl_" + el_id).attr("id", "acl_" + new_id).attr("name", "acl_" + new_id);
                        parent_div.find("#pp" + index).find("#signature_" + el_id).attr("id", "signature_" + new_id).attr("name", "signature_" + new_id);
                        parent_div.find("#pp" + index).find("#policy_" + el_id).attr("id", "policy_" + new_id).attr("name", "policy_" + new_id);
                        parent_div.find("#pp" + index).find("#success_action_status_" + el_id).attr("id", "success_action_status_" + new_id).attr("name", "success_action_status_" + new_id);
                        parent_div.find("#pp" + index).find(".style").attr("id", "style_" + index);
                        parent_div.find("#pp" + index).find(".style").attr("style", "display:none");

                        var pp_field_paper = parent_div.find("#pp" + index).find(".paper");
                        pp_field_paper.attr("id", new_id);
                        var pp_field_name = pp_field_paper.attr("name");
                        var pp_name = pp_field_name.split("attachment").join("").match(/\d+/g).last();
                        var pos = pp_field_name.lastIndexOf(pp_name);
                        var new_name = pp_field_name.slice(0, pos) + pp_field_name.slice(pos).replace(pp_name, d);
                        pp_field_paper.attr("name", new_name);
                        parent_div.find("#pp" + index).find(".hidden_field").remove();
                        parent_div.find("#pp" + index).find(".remove-field").attr("style", "display:block").attr("id", "remove-field-" + index).attr("data-value", index).attr("data-time", d);
                        _id = i == 0 ? el_id : new_id;
                        id_arr[d] = new_id;
                        new_id_arr[index] = d;

                        str_val = "#field_" + id_arr[d];
                        str[d] = str_val;

                        pgb_val = "#progressbar_" + id_arr[d];
                        pgb[index] = pgb_val;

                        pgbout_val = "#progressbarout_" + id_arr[d];
                        pgb_out[index] = pgbout_val;

                        pgbin_val = "#progressbarin_" + id_arr[d];
                        pgb_in[index] = pgbin_val;

                        remove_field_val = "#remove-field-" + index;
                        remove_field[d] = remove_field_val;

                        label_text_val = '#field_' + id_arr[d];
                        label_text[d] = label_text_val;

                        if (j(el).attr('direct') == "true") {
                            j(str).val(el.files[i].name.truncate(15));
                            j(str).attr("title", el.files[i].name);
                            j(el).attr("title", el.files[i].name);
                        } else if (j(el).attr('direct') == "false") {
//                            error_text_val = '#error_' + id_arr[d];
//                            error_text[d] = error_text_val;
                            upload_file_name[d] = attachment_set[index].name;
                            file = attachment_set[index];
                            upload_files[d] = attachment_set[index];

                            file_name = unescape(attachment_set[index].name).replace(/[\n\r\s+%]/g, '_');
                            j("#key_" + id_arr[d]).val('temp/' + d + '/' + file_name);
                            //            var url = 'https://fedena_res.s3.amazonaws.com/';
                            var url = s3_url;
                            //xhr_arr.push(new XMLHttpRequest());
                            xhr_arr[index] = new XMLHttpRequest();

                            xhr_arr[index].upload.addEventListener("loadstart", function (evt) {
                                j(label_text[new_id_arr[index]]).attr("style", "display: none");
                                parent_div.find(remove_field[new_id_arr[index]]).attr("style", "display: none");
                                j(pgb[index]).attr("style", "display: inline-block");
                                j('input[type=submit]').attr('disabled', true);
                            }, false);

                            xhr_arr[index].upload.addEventListener("error", function (evt) {
                                //file_value.value = '';
                                if (form_enabled() == true)
                                {
                                    j('input[type=submit]').attr('disabled', false);
                                }
                                j(label_text[[new_id_arr[progress_index]]]).attr("style", "display: inline-block");
                                j(pgb[new_id_arr[progress_index]]).attr("style", "display: none");

                            });
                            xhr_arr[index].upload.addEventListener("abort", function (evt) {
                                file_value.value = '';
                                if (form_enabled() == true)
                                {
                                    j('input[type=submit]').attr('disabled', false);
                                }
                                j(label_text[new_id_arr[progress_index]]).attr("style", "display: inline-block");
                                j(pgb[new_id_arr[progress_index]]).attr("style", "display: none");
                            });
                            var t = null;
                            xhr_arr[index].upload.addEventListener("progress", function (evt) {

                                if (typeof t !== 'undefined' || t != null) {
                                    clearTimeout(t);
                                }
                                t = setTimeout(function (e) {
                                    var timeout = true;
                                    this.abort();
                                }, 5000);

                                progressBar = j(pgb_out[progress_index]);
                                if (evt.lengthComputable) {
                                    progressBar.max = evt.total;
                                    progressBar.value = evt.loaded;
                                    j(pgb_in[progress_index]).attr("style", 'width:' + Math.round(evt.loaded / evt.total * 100) + 'px');
                                }
                            }, false);

                            xhr_arr[index].upload.addEventListener("load", function (evt) {
                                if (typeof t !== 'undefined' || t != null) {
                                    clearTimeout(t);
                                }
                                progress_index++;
                                obj.pgb = pgb;
                                obj.pgb_in = pgb_in;
                                obj.pgb_out = pgb_out;
                                obj.progress_index = progress_index;
                            }, false);

                            xhr_arr[index].onreadystatechange = function () {
                                if (this.readyState == 4 && null != this.status && (this.status == 200 || this.status == 201
                                        || this.status == 202 || this.status == 204 || this.status == 205 || this.status == 0)) {
                                    if (this.status == 201) {
                                        _key = j(this.responseText).find('key').text();
                                        _res = _key.match(/temp\/(\d+)\/.*/);
                                        idf = _res[1];
                                        pg_bar = pgb.find(a => a.includes(idf));
                                        j(pg_bar).attr("style", "display: none");
                                        j(str[idf]).attr("style", "display: inline-block");
                                        parent_div.find(remove_field[idf]).attr("style", "display: inline-block");
                                        j(str[idf]).val(upload_file_name[idf].truncate(15));
                                        j(str[idf]).attr("title", upload_file_name[idf]);
                                        j("#" + id_arr[idf] + ".paper").attr("title", upload_file_name);
                                        if (form_enabled() == true)
                                        {
                                            j('input[type=submit]').attr('disabled', false);
                                        }
                                        j.event.trigger({
                                            type: "upload",
                                            message: id_arr[idf], //file_value.id,
                                            file_name: file_name,
                                            time: new Date()
                                        });
                                        //file_value.value = '';
                                        file_id = "#" + id_arr[idf];
                                        j(file_id).attr("value");
                                        j(file_id).attr("value", '');


                                        var url_id = id_arr[idf];//file_value.id                                      
                                        url = j(this.responseText).find('location').text() + '?content_type=' + upload_files[idf].type + '&file_size=' + upload_files[idf].size;//.gsub('%2F','/');

                                        j("#" + url_id + ":not(.hidden_field)").attr('type', "hidden");
                                        j("#" + url_id + ":not(.hidden_field)").val(url);
                                        j("#" + url_id + ':not(.paper)').attr('disabled', 'disabled');
                                        x = new_id_arr[count];
                                        j("#style_" + count).children().each(function (ele, val) {                                           
                                            if (val.id != id_arr[x]) {
                                                j(val).attr('disabled', 'disabled');
                                            }
                                        });
                                        count++;  
                                        obj.count = count;

                                    } else if (this.status == 0 || this.status == 4) {

                                        j("#" + id_arr[d]).attr("value", '');
                                        j("#" + id_arr[d]).get(0).value = ""
                                        j("#" + id_arr[d]).get(0).type = "file"
                                        j(str).val(no_file_chosen_label);
                                        j(str).attr("title", "");
                                        j(this).attr("title", "No file chosen");
                                        j.event.trigger({
                                            type: "upload_failure",
                                            message: j("#" + id_arr[i]).attr("id"),
                                            time: new Date()
                                        });
                                    }
                                } else if (this.readyState == 4) {
                                } else if (this.readyState == 400) {
                                }
                            }
                            var params = {
                                'key': j('#key_' + id_arr[d]).val(),
                                'acl': j('#acl_' + id_arr[d]).val(),
                                'success_action_status': j('#success_action_status_' + id_arr[d]).val(),
                                'AWSAccessKeyId': j('#AWSAccessKeyId_' + id_arr[d]).val(),
                                'policy': j('#policy_' + id_arr[d]).val(),
                                'signature': j('#signature_' + id_arr[d]).val(),
                                'file': file
                            };
                            var fData = new FormData();
                            for (var p in params) {
                                fData.append(p, params[p]);
                            }
                            xhr_arr[index].open("POST", url, true);
                            xhr_arr[index].send(fData);

                        }
                        index++;
                    } else {
                        parent_div.next('#attachment-error').css("display", "inline-block");
                        parent_div.next('#attachment-error').children('.error-msg').html("File not supported or larger in size");

                    }
                } else {
                    parent_div.next('#attachment-error').css("display", "inline-block");
                    parent_div.next('#attachment-error').children('.error-msg').html("Can upload upto 5 files");

                }
                if (i == el.files.length - 1) {
                    el.value = "";
                }
            }
            this.attachment_set = attachment_set;
            this.index = index;
            this.id_arr = id_arr;
            this.new_id_arr = new_id_arr;
            
        }
    }

    this.remove_uploaded_file_test = function (elem, u_id) {

        var attachment_set = this.attachment_set;
        var pgb = this.pgb;
        var pgb_in = this.pgb_in;
        var pgb_out = this.pgb_out;
        var index = this.index;
        var count = this.index;
        var progress_index = this.progress_index;
        var id = j(elem).closest('.remove-field').attr("data-value");
        var time_id = j(elem).closest('.remove-field').attr("data-time");
        reset_data_value_s3(attachment_set, id);
        j("#deletepreview").remove();
        scroll_div = j("#conversations-scroll").height();
        att_div = j(".paperclip_field").height();

        if (u_id == 'reply_message') {
            j("#conversations-scroll").css("height", scroll_div + att_div + "px");
        }
        pgb = remove_file_s3(pgb, id);
        pgb_in = remove_file_s3(pgb_in, id);
        pgb_out = remove_file_s3(pgb_out, id);
        attachment_set = remove_file_s3(attachment_set, id);

        this.attachment_set = attachment_set;
        this.pgb = pgb;
        this.pgb_in = pgb_in;
        this.pgb_out = pgb_out;

        if (this.attachment_set.length == 0) {
            j("#conversations-scroll").css("height", "494px");
        }
        index--;
        this.index = index;
        count--;
        this.count = count;
        progress_index--;
        this.progress_index = progress_index;
    }
}

function remove_file_s3(files, id) {
    var new_set = [];
    for (var i = 0; i < files.length; i++) {
        if (i != id) {
            new_set.push(files[i]);
        }
    }
    return new_set;
}

function reset_data_value_s3(attachment_set, id) {
    var k = 0;
    for (var i = 0; i < attachment_set.length; i++) {
        if (i != id) {
            //j("#tag"+i).data("value",k);
            j("#remove-field-" + i).attr("data-value", k);
            j(("#pp" + i)).attr("id", "pp" + k);
            j(("#style_" + i)).attr("id", "style_" + k);
            j("#remove-field-" + i).attr("id", "remove-field-" + k);
            k++;
        } else {
            j("#pp" + i).attr("id", "deletepreview");
            j(("#style_" + i)).attr("id", "deletestyle");
            j("#remove-field-" + i).attr("id", "stubtag");
        }
    }
}

function paperclip_file_upload(e, el) {
    var no_file_chosen_label = 'No file selected';
    var el_id = el.id;
    var str = "#field_" + el_id;
    var file_value = el;
    if (j(el).attr('direct') == "true") {
        j(str).val(el.files[0].name.truncate(15));
        j(str).attr("title", el.files[0].name);
        j(el).attr("title", el.files[0].name);
    } else if (j(el).attr('direct') == "false") {
        var error_text = '#error_' + el.id;
        var upload_file_name = el.files[0].name
        var file = el.files[0];
        var max_file_size;
        var file_types;
        j(el).parent().children().each(function (ele, val) {
            j(val).removeAttr('disabled');
            if (val.id.indexOf("max_file_size") >= 0) {
                max_file_size = val.value;
            } else if (val.id.indexOf("file_types") >= 0) {
                file_types = val.value;
            }
        });

        file_name = unescape(el.files[0].name).replace(/[\n\r\s+%]/g, '_');
        if (max_file_size > file.size && ((file_types.search(file.type) >= 0 && file_types.length != 0 && file.type.length != 0) || file_types.length == 0)) {
            j(error_text).attr("style", "display: none");

            var pgb = "#progressbar_" + file_value.id;
            var pgb_out = "#progressbarout_" + file_value.id;
            var pgb_in = "#progressbarin_" + file_value.id;
            var label_text = '#field_' + file_value.id;
            j('#key_' + el_id).attr('value', 'temp/' + e.timeStamp + '/' + file_name);
//            var url = 'https://fedena_res.s3.amazonaws.com/';
            var url = s3_url;
            var xhr = new XMLHttpRequest();
            xhr.upload.addEventListener("loadstart", function (evt) {
                j(label_text).attr("style", "display: none");
                j(pgb).attr("style", "display: inline-block");
                j('input[type=submit]').attr('disabled', true);
                if (form_enabled() == true)
                {
                    j('input[type=submit]').attr('disabled', false);
                }
            }, false);
            xhr.upload.addEventListener("error", function (evt) {
                file_value.value = '';
                if (form_enabled() == true)
                {
                    j('input[type=submit]').attr('disabled', false);
                }
                j(label_text).attr("style", "display: inline-block");
                j(pgb).attr("style", "display: none");

            });
            xhr.upload.addEventListener("abort", function (evt) {
                //file_value.value = '';
                if (form_enabled() == true)
                {
                    j('input[type=submit]').attr('disabled', false);
                }
                j(label_text).attr("style", "display: inline-block");
                j(pgb).attr("style", "display: none");
            });
            var t = null;
            xhr.upload.addEventListener("progress", function (evt) {
                if (typeof t !== 'undefined' || t != null) {
                    clearTimeout(t);
                }
                t = setTimeout(function (e) {
                    var timeout = true;
                    xhr.abort();
                }, 5000);
                var progressBar = j(pgb_out);
                var percentageDiv = document.getElementById(pgb_in);

                if (evt.lengthComputable) {

                    progressBar.max = evt.total;
                    progressBar.value = evt.loaded;
                    j(pgb_in).attr("style", 'width:' + Math.round(evt.loaded / evt.total * 100) + 'px');

                }

            }, false);
            xhr.upload.addEventListener("load", function (evt) {
                if (typeof t !== 'undefined' || t != null) {
                    clearTimeout(t);
                }
                j(pgb).attr("style", "display: none");
                j(label_text).attr("style", "display: inline-block");
                if (form_enabled() == true)
                {
                    j('input[type=submit]').attr('disabled', false);
                }
            }, false);
            xhr.onreadystatechange = function () {
                if (this.readyState == 4 && null != this.status && (this.status == 200 || this.status == 201
                        || this.status == 202 || this.status == 204 || this.status == 205 || this.status == 0)) {
                    if (xhr.status == 201) {
                        j(str).val(upload_file_name.truncate(15));
                        j(str).attr("title", upload_file_name);
                        j("#" + el_id + ".paper").attr("title", upload_file_name);
                        j.event.trigger({
                            type: "upload",
                            message: file_value.id,
                            file_name: file_name,
                            time: new Date()
                        });
                        file_value.value = '';
                        var url_id = file_value.id
                        url = j(xhr.responseText).find('location').text() + '?content_type=' + file.type + '&file_size=' + file.size;//.gsub('%2F','/');
                        j("#" + url_id).get(0).type = "hidden";
                        j("#" + url_id).get(0).value = url;

                        j(el).parent().children().each(function (ele, val) {
                            if (val.id != el_id) {
                                j(val).attr('disabled', 'disabled');
                            }
                        });
                    } else if (xhr.status == 0 || xhr.status == 4) {
                        file_value.value = '';
                        j("#" + el_id).get(0).value = ""
                        j("#" + el_id).get(0).type = "file"
                        j(str).val(no_file_chosen_label);
                        j(str).attr("title", "");
                        j(this).attr("title", "No file chosen");
                        j.event.trigger({
                            type: "upload_failure",
                            message: file_value.id,
                            time: new Date()
                        });
                    }
                } else if (this.readyState == 4) {
                    //console.log('fail ');
                } else if (this.readyState == 400) {
                    //console.log('failed to upload');
                }
            }
            var params = {
                'key': j('#key_' + el_id).val(),
                'acl': j('#acl_' + el_id).val(),
                'success_action_status': j('#success_action_status_' + el_id).val(),
                'AWSAccessKeyId': j('#AWSAccessKeyId_' + el_id).val(),
                'policy': j('#policy_' + el_id).val(),
                'signature': j('#signature_' + el_id).val(),
                'file': file
            };

            var fData = new FormData();

            for (var p in params) {
                fData.append(p, params[p]);
            }

            xhr.open("POST", url, true);
            xhr.send(fData);

        } else
        {
            upload_failure(file_value, error_text, el, str, no_file_chosen_label)
        }
    }
}

function upload_failure(file_value, error_text, el, str, no_file_chosen_label) {
    file_value.value = '';
    j(error_text).attr("style", "display: block");
    j("#" + el.id).get(0).value = ""
    j("#" + el.id).get(0).type = "file"
    j(str).val(no_file_chosen_label);
    j(str).attr("title", "");
    j(el).attr("title", "No file chosen");
    j.event.trigger({
        type: "upload_failure",
        message: file_value.id,
        time: new Date()
    });
}

function form_enabled() {
    var enbl = true;
    j(".pgbar").each(function () {
        if (j(this).css("display") != "none")
        {
            enbl = false;
        }
    });
    return enbl;
}

function abort() {
    if (form_enabled() == true)
    {
        j('input[type=submit]').attr('disabled', false);
    }
}



j(document).ready(function () {
    reset_values();
});
