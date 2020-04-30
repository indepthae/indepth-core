if (typeof RedactorPlugins == "undefined") var RedactorPlugins = {};
RedactorPlugins.s3_image_upload = {

    imageS3Callback: function(data, r)
    {
        this.imageS3Insert(data, false, r);
    },
    imageS3Insert: function(json, link, r)
    {
        this.selectionRestore();

        if (json !== false)
        {
            var html = '';
            if (link !== true)
            {
                html = '<img id="image-marker" src="' + json.filelink + '" />';

                var parent = this.getParent();
                if (this.opts.paragraphy && j(parent).closest('li').size() == 0)
                {
                    html = '<p>' + html + '</p>';
                }
            }
            else
            {
                html = json;
            }

            this.insertS3Html(html, false, r);

            var image = j(this.$editor.find('img#image-marker'));

            if (image.length) image.removeAttr('id');
            else image = false;
            r.sync();

            // upload image callback
            link !== true && this.callback('imageUpload', image, json);
        }

        r.modalClose();
        r.observeImages();
    },
    insertS3Html: function (html, sync, r)
    {
        var current = this.getCurrent();
        var parent = current.parentNode;

        //        r.focusWithSaveScroll();

        r.bufferSet();

        var $html = j('<div>').append(j.parseHTML(html));
        html = $html.html();

        html = r.cleanRemoveEmptyTags(html);

        // Update value
        $html = j('<div>').append(j.parseHTML(html));
        var currBlock = r.getBlock();

        if ($html.contents().length == 1)
        {
            var htmlTagName = $html.contents()[0].tagName;

            // If the inserted and received text tags match
            if (htmlTagName != 'P' && htmlTagName == currBlock.tagName || htmlTagName == 'PRE')
            {
                //html = $html.html();
                $html = j('<div>').append(html);
            }
        }

        if (this.opts.linebreaks)
        {
            html = html.replace(/<p(.*?)>([\w\W]*?)<\/p>/gi, '$2<br>');
        }

        // add text in a paragraph
        if (!r.opts.linebreaks && $html.contents().length == 1 && $html.contents()[0].nodeType == 3
            && (r.getRangeSelectedNodes().length > 2 || (!current || current.tagName == 'BODY' && !parent || parent.tagName == 'HTML')))
            {
            html = '<p>' + html + '</p>';
        }

        html = r.setSpansVerifiedHtml(html);

        if ($html.contents().length > 1 && currBlock)
        //        || $html.contents().is('p, :header, ul, ol, li, div, table, td, blockquote, pre, address, section, header, footer, aside, article')
    
        {
            if (r.browser('msie'))
            {
                if (!r.isIe11())
                {
                    r.document.selection.createRange().pasteHTML(html);
                }
                else
                {
                    r.execPasteFrag(html);
                }
            }
            else
            {
                r.document.execCommand('inserthtml', false, html);
            }
        }
        else r.insertHtmlAdvanced(html, false);

        if (r.selectall)
        {
            r.window.setTimeout($.proxy(function()
            {
                if (!r.opts.linebreaks) this.selectionEnd(this.$editor.contents().last());
                else r.focusEnd();

            }, this), 1);
        }

        r.observeStart();

        // set no editable
        r.setNonEditable();

        if (sync !== false) r.sync();
    },
    uploadS3Init: function(r, el, options){
        
        this.uploadOptions = {
            url: false,
            success: false,
            error: false,
            start: false,
            trigger: false,
            auto: false,
            input: false
        };
        j.extend(this.uploadOptions, options);

        var $el = j('#' + el);

        // Test input or form
        if ($el.length && $el[0].tagName === 'INPUT')
        {
            this.uploadOptions.input = $el;
            this.el = j($el[0].form);
        }
        else this.el = $el;

        this.element_action = this.el.attr('action');

        // Auto or trigger
        if (this.uploadOptions.auto)
        {
            j(this.uploadOptions.input).change(j.proxy(function(e)
            {
                file = $el[0].files[0];
                file_ext = file.name.match(/[.]/) && file.name.match(/[^.*]$/)
                type = file.type;
                now = Date.now();
                ts = now + parseInt(Math.random()*1000);
                valid_file_types = r.opts.valid_image_types.split(',');
                if(type && valid_file_types.indexOf(type) > -1 && file_ext){
                    file_name = now+'.'+type.split('/').last();
                    key = 'temp/'+ts+'/'+file_name;
                    j('#key').val(key);
                    var url = r.opts.public_bucket_url;
                    var xhr = new XMLHttpRequest();


                    xhr.upload.addEventListener("loadstart", function(evt){

                        j('#redactor-progress').show();
                        j('#redactor-progress-bar').css('width','0%');
                        
                    }, false);
                    
                    var t = null;
                    xhr.upload.addEventListener("progress", function(evt){
                        if(typeof t !== 'undefined' || t!=null){
                            clearTimeout(t);
                        }
                        t = setTimeout(function(e){
                            var timeout = true;
                            xhr.abort();
                        },5000);
                        if (evt.lengthComputable) {
                            j('#redactor-progress-bar').css('width',(Math.round(evt.loaded / evt.total * 100))+'%');

                        }

                    }, false);
                    xhr.onreadystatechange=function(){
                        if (this.readyState==4&&null!=this.status&&(this.status==200||this.status==201
                            ||this.status==202||this.status==204||this.status==205||this.status==0)){
                            if(xhr.status == 201){
                                j.ajax({
                                    url: '/redactor/post_upload',
                                    method: 'post',
                                    data: {
                                        key: key
                                    },
                                    success: function(data){
                                        if(data.error !== undefined){
                                            r.modalClose();
                                            r.callback('imageUploadError', data);
                                        }else{
                                            r.imageS3Callback(data, r);
                                        }
                                    }
                                });
                            }
                            else if(xhr.status == 0 || xhr.status == 4 )
                            {
                                r.modalClose();
                                r.callback('imageUploadError', {
                                    error: "upload failure",
                                    error_message: "Failed to upload. Kindly check your S3 settings and try again after sometime !!!"
                                });
                            }
                        }else if (this.readyState==4){
                        //console.log('fail ');
                        }else if (this.readyState==400){
                    //console.log('failed to upload');
                    }
                    }
                    var params = {
                        'key':j('#key').val(),
                        'acl':j('#acl').val(),
                        'success_action_status': 201, //j('#success_action_redirect').val(),
                        'AWSAccessKeyId':j('#AWSAccessKeyId').val(),
                        'policy':j('#policy').val(),
                        'signature':j('#signature').val(),
                        'file':file
                    };

                    var fData = new FormData();

                    for(var p in params){
                        fData.append(p,params[p]);
                    }

                    xhr.open("POST", url, true);
                    xhr.send(fData);
                }else{
                    js_error = {
                        error: "Unsupported file",
                        error_message: "Select file is not a valid image. Please upload an image of "+ valid_file_types.join(',')
                    }
                    r.opts.imageUploadErrorCallback(js_error);
                    r.modalClose();
                }

            }, this));

        }
        else if (this.uploadOptions.trigger)
        {
            j('#' + this.uploadOptions.trigger).click(j.proxy(this.uploadSubmit, this));
        }
    },
    
    imageS3Show: function()
    {
        this.selectionSave();
        var callback = j.proxy(function()
        {

            if (this.opts.imageUpload || this.opts.s3)
            {

                if (this.opts.s3 === false)
                {
                    // ajax upload
                    this.uploadS3Init(this, 'redactor_file', {
                        auto: true,
                        url: this.opts.imageUpload,
                        success: j.proxy(this.imageCallback, this),
                        error: j.proxy(function(obj, json)
                        {
                            this.callback('imageUploadError', json);

                        }, this)
                    });
                }
                // s3 upload
                else
                {
                    j('#redactor_file').on('change.redactor', j.proxy(this.s3handleFileSelect, this));
                }

            }

            j('#redactor_upload_btn').click(j.proxy(this.imageS3CallbackLink, this));

            if (!this.opts.imageUpload && !this.opts.imageGetJson)
            {
                setTimeout(function()
                {
                    j('#redactor_file_link').focus();

                }, 200);
            }

        }, this);

        this.modalInit(this.opts.curLang.image, this.opts.modal_s3_image, 610, callback);

    },    
    
    init: function () {
        this.opts.modal_s3_image= String()
        + '<section id="redactor-modal-image-insert">'
        + '<div id="redactor_tabs">'
        + '<a href="#" id="redactor-tab-control-1" class="redactor_tabs_act">' + this.opts.curLang.upload + '</a>'
        //        + '<a href="#" id="redactor-tab-control-2">' + this.opts.curLang.choose + '</a>'
        //        + '<a href="#" id="redactor-tab-control-3">' + this.opts.curLang.link + '</a>'
        + '</div>'
        + '<form id="redactorInsertImageForm" method="post" action="" enctype="multipart/form-data">'
        + '<div id="redactor_tab1" class="redactor_tab">'
        + '<div id="redactor-progress" class="redactor-progress redactor-progress-striped" style="">'
        + '<div id="redactor-progress-bar" class="redactor-progress-bar" style="width: 0%;"></div>'
        + '</div>'
        + '<input type="file" id="redactor_file" name="' + this.opts.imageUploadParam + '" />'
        + '</div>'
        + '</form>'
        + '</section>'
        + '<footer>'
//        + '<button class="redactor_modal_btn redactor_btn_modal_close">' + this.opts.curLang.cancel + '</button>'
//        + '<button class="redactor_modal_btn redactor_modal_action_btn" id="redactor_upload_btn">' + this.opts.curLang.insert + '</button>'
        + '</footer>';
        this.buttonAddBefore("video", "s3_image", "Insert image", j.proxy(function () {            
            this.imageS3Show();
            j('#redactor-progress').hide();
        }, this));
    }
    
}