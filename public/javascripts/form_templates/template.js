/** initialise globals **/
var form_data_old = {};
var form_data = {};
var currentMousePos = {
    x: -1,
    y: -1
};
var initial_style = '';
var droppable_check = false;
var drag_or_click = false;
var options = [];
var clone;
var dir = j('html').attr('dir');
/** initialise globals **/
var dselected = false;
window.onload = function(){
    j('.dragplaceholder').on('mouseover',function(){
        data = j(this).attr('attr-data');
        j('.fields_tab ul li[attr-data='+data+']').css('background','#eaf3fc');

        j(this).css('opacity',"0");

    });
    j('.dragplaceholder').on('mouseout',function(){
        data = j(this).attr('attr-data');
        j('.fields_tab ul li[attr-data='+data+']').css('background','#eee');
        j(this).css('opacity',0.2);
    });
    j(document).delegate('.dragplaceholder','mousedown',function(){
        var selected = false;
        data = j(this).attr('attr-data');
        j(this).attr('id','drag_'+data);
        obj = j('.fields_tab ul li[attr-data='+data+']');
        if((obj.index() + 1) % 3 != 0){
            obj.css('width',102);
        }
        obj.css('background','#eaf3fc').css('border','0px');
        j(this).css('opacity',0);
        selected = true;
        j(this).attr('data-selected',1);
    });
    j(document).delegate('.dragplaceholder','mousemove',function(){
        selected = j(this).attr('data-selected');
        if(selected !== undefined){
            data = j(this).attr('attr-data');
            j('.dragplaceholder[attr-dat='+data+']').each(function(x,y){
                j(y).css('opacity',0.2);
            });
            j('.fields_tab ul li[attr-data='+data+']').css('background','#eee');
            j('#drag_'+data).css('opacity',0.2);
            j(this).removeAttr('data-selected');
        }else{
    }
    });
    j(document).delegate('.template_element_selection .dragplaceholder','mouseup',function(){
        data = j(this).attr('attr-data');
        j('.fields_tab ul li[attr-data='+data+']').removeAttr('style');
        j(this).css('opacity',0.2);
    });
    var submit_field = j('#form_template_submit');
    // identify if template is new or for update
    action = submit_field.attr('data') === undefined ? 'create' : submit_field.attr('data') == 'edit' ? 'update' : 'create';
    if(action == 'update'){
        form_data_old = {
            'form_template': {
                'name': j('#form_template_name').val()
            }
        };
        if(action == 'update'){
            form_data_old['form_template']['id'] = j('#form_template_id').val();
        }
        form_data_old['publish'] = j(this).hasClass('publish') ? true : false;
        var type_arr = ['select','radio','checkbox'];
        j('.field_block').each(function(a,b){
            var id = j(b).attr('id').split('_').last();
            var type = j(b).attr('attr-type');
            var field_type;
            if(type == 'hr'){
                field_type = 'form_field_horizontal_rules_attributes';
            }else if(type == 'checkbox'){
                field_type = 'form_field_checkboxes_attributes';
            }
            else{
                field_type = 'form_field_'+type+'s_attributes';
            }
            if(form_data_old['form_template'][field_type] == undefined){
                form_data_old['form_template'][field_type] = {};
            }
            form_data_old['form_template'][field_type][id] = {};
            form_data_old['form_template'][field_type][id]['placement_order'] = a;
            form_data_old['form_template'][field_type][id]['label'] = j(b).find('.main_label').text();
            form_data_old['form_template'][field_type][id]['field_type'] = j(b).attr('attr-type');
            field_settings = {};
            field_settings['description'] = j(b).find('.main_label').next().text();
            field_settings['mandatory'] = j(b).find('.main_label').attr('attr_mandatory');
            form_data_old['form_template'][field_type][id]['field_settings'] = JSON.stringify(field_settings);
            if(j.inArray(j(b).attr('attr-type'),type_arr) >= 0){
                form_data_old['form_template'][field_type][id]['form_field_options_attributes'] = {};
                j(b).find('.input_text_field label').each(function(x,y){
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x] = {}
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['label'] = j(y).text();
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['value'] = j(y).text();
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['weight'] = j(y).attr('data_weight');
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['placement_order'] = x;
                });

                j(this).find('option').each(function(x,y){
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x] = {}
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['label'] = j(y).text();
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['value'] = j(y).text();
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['weight'] = j(y).attr('data_weight');
                    form_data_old['form_template'][field_type][id]['form_field_options_attributes'][x]['placement_order'] = x;
                })
            }
        });
    }

}

j(document).delegate('.field_block','mouseover',function(){
    j(this).find('.delete_field').css('display','block').css('top',-(5+j(this).height()/2)+'px');
});
j(document).delegate('.field_block','mouseout',function(){
    j(this).find('.delete_field').attr('style','');
});

j(document).ready(function(){
    //gets current position of mouse
    j(document).mousemove(function(event) {
        currentMousePos.x = event.pageX;
        currentMousePos.y = event.pageY;
    });

    j('.template_element_selection > .tabs > ul > li').on('click',function(){
        if(j(this).attr('attr-data')=='fields'){
            j('.dragplaceholder').css('display','').css('z-index','');
        }
        var ele = j(this);
        change_tab(ele);
    });

    j('.submit').on('click',function(e){
        e.preventDefault();
    });

    j('#form_template_submit,#submit_publish').on('click',function(e){
        var send_request = true;
        action = j(this).attr('data') === undefined ? 'create' : j(this).attr('data') == 'edit' ? 'update' : 'create';
        form_data = {
            'form_template': {
                'name': j('#form_template_name').val()
            }
        };
        if(action == 'update'){
            form_data['form_template']['id'] = j('#form_template_id').val();
        }
        form_data['publish'] = j(this).hasClass('publish') ? true : false;
        var type_arr = ['select','radio','checkbox'];
        j('.field_block').each(function(a,b){
            var id = j(b).attr('id').split('_').last();
            var type = j(b).attr('attr-type');
            var field_type;
            if(type == 'hr'){
                field_type = 'form_field_horizontal_rules_attributes';
            }else if(type == 'checkbox'){
                field_type = 'form_field_checkboxes_attributes';
            }
            else{
                field_type = 'form_field_'+type+'s_attributes';
            }
            if(form_data['form_template'][field_type] == undefined){
                form_data['form_template'][field_type] = {};
            }
            form_data['form_template'][field_type][id] = {};
            if(j(b).attr('attr_life')===undefined || j(b).attr('attr_life')!='new'){
                form_data['form_template'][field_type][id]['id'] = id;
            }
            if(j(b).attr('_delete') !== undefined){
                form_data['form_template'][field_type][id]['_delete'] = 1;
            }else{
                form_data['form_template'][field_type][id]['placement_order'] = a;
            }
            form_data['form_template'][field_type][id]['label'] = j(b).find('.main_label').text();
            form_data['form_template'][field_type][id]['field_type'] = j(b).attr('attr-type');
            field_settings = {};
            field_settings['description'] = j(b).find('.main_label').next().text();
            field_settings['mandatory'] = j(b).find('.main_label').attr('attr_mandatory');
            form_data['form_template'][field_type][id]['field_settings'] = JSON.stringify(field_settings);
            if(j.inArray(j(b).attr('attr-type'),type_arr) >= 0){
                form_data['form_template'][field_type][id]['form_field_options_attributes'] = {};
                j(b).find('.input_text_field input').each(function(x,y){
                    form_data['form_template'][field_type][id]['form_field_options_attributes'][x] = {}
                    if(action == 'update' && (j(y).attr('attr_life')===undefined || j(y).attr('attr_life')!='new')){
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['id'] = j(y).attr('id').split('_')[1];
                    }
                    if(j(y).attr('_delete') !== undefined){
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['_delete'] = 1;
                    }
                    form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['label'] = j(y).val();
                    form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['value'] = j(y).val();
                    form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['weight'] = j(y).attr('data_weight');
                    form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['placement_order'] = x;
                });
                if(j(b).attr('attr-type') == 'select'){
                    xy = 0;
                    j(b).find('select > option').each(function(x,y){
                        xy = x;
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x] = {}
                        if(action == 'update' && (j(y).attr('attr_life')===undefined || j(y).attr('attr_life')!='new')){
                            form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['id'] = j(y).attr('attr_id');
                        }
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['label'] = j(y).text();
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['value'] = j(y).text();
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['weight'] = j(y).attr('data_weight');
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][x]['placement_order'] = x;
                    });
                    xy++;
                    j(b).find('.deleted_select_options .del_option').each(function(x,y){
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][xy] = {}
                        if(action == 'update' && (j(y).attr('attr_life')===undefined || j(y).attr('attr_life')!='new')){
                            form_data['form_template'][field_type][id]['form_field_options_attributes'][xy]['id'] = j(y).attr('attr_id');
                        }
                        if(j(y).attr('_delete') !== undefined){
                            form_data['form_template'][field_type][id]['form_field_options_attributes'][xy]['_delete'] = 1;
                        }
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][xy]['label'] = j(y).text();
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][xy]['value'] = j(y).text();
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][xy]['weight'] = j(y).attr('data_weight');
                        form_data['form_template'][field_type][id]['form_field_options_attributes'][xy]['placement_order'] = xy;
                    })
                }
            }
        });
        if(action=='update'){
            old_hash = JSON.stringify(form_data_old);
            new_hash = JSON.stringify(form_data);
            if(old_hash == new_hash){

            }else{
                send_request = true;
            }
        }
        if(send_request){
            j.ajax({
                type: "POST",
                url: '/form_templates/' + action + '/',
                data: form_data,
                success: function (data) {
                    var form_template_id = j('#template_id').html();
                    var publish = j('#publish').text().trim();
                    if(j('#errors').length > 0){
                        j('#errors_pane').css('display','block');
                        j('.errorExplanation').prepend('<div class="hide_error"></div>');
                        j('.template_form_contents').scrollTop(0);
                    }else if(j('#errors').length == 0 && publish!=''){
                        j('#errors_pane').css('display','');
                        location.href = publish == 'false' ? '/form_templates/'+j.trim(form_template_id)+'/preview' : '/forms/'+j.trim(form_template_id)+'/publish';
                    }else{
                        location.href = '/form_templates/'+j.trim(form_template_id)+'preview';
                    }
                }
            });
        }else{

        }
        j(document).delegate('.hide_error','click',function(){
            j('#errors_pane').css('display','');
        })
    });

    j(document).delegate('#field_collection input','change',function(){
        var id = j('#field_id').val();
        var block = '#field_block_'+id;
        if(j(this).attr('id').split('_')[0]=='mandatory'){
            if(j(this).is(':checked')){
                j(block).find('.main_label').addClass('mandatory');
                j(block).find('.main_label').attr('attr_mandatory','true');
            }else{
                j(block).find('.main_label').removeClass('mandatory');
                j(block).find('.main_label').attr('attr_mandatory','false');
            }
        }
    });
    j(document).delegate('#field_collection input,#field_collection textarea','input',function(){
        var id = j('#field_id').val();
        var block = '#field_block_'+id;
        var desc = 'description_label_'+id;
        if(j(this).is('textarea')){
            if(j('#'+desc).length==0){
                desc_block = j('<div>').attr('id',desc).attr('class','description_label').text(j(this).val());
                j(block+' .main_label').after(desc_block[0]);
            }else{
                j('#'+desc).text(j(this).val());
            }
        }else if(j(this).attr('id').split('_')[0] != 'weight'){
            var value = j(this).val();
            if(j(this).attr('id') == 'main_label'){
                j(block).find('.main_label').text(value);
            }else if(j(this).attr('attr_type') == 'select'){
                var option_no = j(this).attr('attr_no');
                j(block).find('option:eq('+option_no+')').val(value).text(value);
            }else if(j.inArray(j(this).attr('attr_type'),['checkbox','radio']) >= 0){
                var option_no = j(this).attr('attr_no');
                j(block).find('input:eq('+option_no+')').val(value).next().text(value);
            }
        }else{
            var value = j(this).val();
            if(j(this).attr('attr_type') == 'select'){
                var option_no = j(this).attr('attr_no');
                j(block).find('option:eq('+option_no+')').attr('data_weight',value);
            }else if(j.inArray(j(this).attr('attr_type'),['checkbox','radio']) >= 0){
                var option_no = j(this).attr('attr_no');
                j(block).find('input:eq('+option_no+')').attr('data_weight',value);
            }
        }
    })

    j(document).delegate('.delete_option','click',function(){
        var parent = j(this).parent();
        var field_id = j('#field_id').val();
        var ipt = parent.find('input');
        var option_no = ipt.attr('attr_no');
        var block = '#field_block_'+field_id;
        if(confirm('Are you sure ?')){
            if(ipt.attr('attr_type') == 'select'){
                opt = j(block).find('option:eq('+option_no+')');
                if(j(block).find('.deleted_select_options').length == 0){
                    j('<div class="deleted_select_options">').insertAfter(block+' select');
                }
                opt.attr('_delete',1).attr('class','del_option');
                j(block +' .deleted_select_options').append(opt.clone());
                opt.remove();
                parent.remove();
                j('#'+field_id+' .option_right .small-field :input').each(function(a,b){
                    j(b).attr('attr_no',a);
                });
                j('#'+field_id+' .option_right .smaller-field :input').each(function(a,b){
                    j(b).attr('attr_no',a);
                });
            }else if(j.inArray(ipt.attr('attr_type'),['checkbox','radio']) >= 0){
                j(block).find('input:eq('+option_no+')').parent().hide();
                j(block).find('input:eq('+option_no+')').attr('_delete',1);
                var check_cnt = 0;
                j('#'+field_id+' .option_right .small-field :input').each(function(a,b){
                    j(b).attr('attr_no',a);
                });
                var check_cnt = 0;
                j('#'+field_id+' .option_right .smaller-field :input').each(function(a,b){
                    j(b).attr('attr_no',a);
                });
                parent.hide();
            }

        }
    })

    j(document).delegate('.field_block','click',function(){
        delete_field_pos = j(this).find('.delete_field').offset();
        click_pos = j(this).offset();
        if((currentMousePos.y <= (delete_field_pos.top + 15) && currentMousePos.y >= delete_field_pos.top) && (currentMousePos.x <= (delete_field_pos.left + 15) && currentMousePos.x >= delete_field_pos.left)){
            delete_field = j(this).find('.delete_field');
            delete_field_message = delete_field.attr('attr_message');
            message = delete_field_message === undefined || delete_field_message == '' ? 'Are you sure ?' : delete_field_message;
            if (confirm(message)){
                j(this).attr('_delete','1');
                j(this).parent().hide();
                parent_setting_id = j(this).attr('id').split('_').last();
                j('#'+parent_setting_id).remove();
                display_blank_form();
                ele = j('.template_element_selection > .tabs > ul > li:nth-child(1)');
                change_tab(ele);
            }
        }else{
            var type_arr = ['select','radio','checkbox'];
            var field_block = j(this);
            var id = j(this).attr('id').split('_').last();
            var field_col_id = '#'+id;
            j('.field_form').each(function(a,b){
                j(b).attr('style','');
            })
            ele = j('.template_element_selection > .tabs > ul > li:nth-child(2)');
            change_tab(ele);
            action = j('#submit_publish').attr('data') === undefined ? 'create' : j('#submit_publish').attr('data') == 'edit' ? 'update' : 'create';
            if(j(field_col_id).length==0){
                j('#field_id').remove();
                j('.dragplaceholder').css('display','none');
                var form_data = {
                    'ts': {},
                    'action_type': action
                };
                form_data['ts']['id'] = id;
                form_data['ts'][id] = {};
                form_data['ts'][id]['label'] = j(this).find('.main_label').text();
                form_data['ts'][id]['field_type'] = j(this).attr('attr-type');
                form_data['ts'][id]['mandatory'] = j(this).find('.main_label').attr('attr_mandatory');
                form_data['ts'][id]['description'] = j(this).find('.main_label').next().text();
                if(j.inArray(j(this).attr('attr-type'),type_arr) >= 0){
                    form_data['ts'][id]['options'] = {};
                    j(this).find('.input_text_field input').each(function(x,y){
                        form_data['ts'][id]['options'][x] = {};
                        form_data['ts'][id]['options'][x]['value'] = j(y).val();
                        form_data['ts'][id]['options'][x]['weight'] = j(y).attr('data_weight');
                    })
                    j(this).find('option').each(function(x,y){
                        if(action == 'update'){
                            opt_id = j(y).attr('attr_id');
                            form_data['ts'][id]['options'][opt_id] = {};
                            form_data['ts'][id]['options'][opt_id]['value'] = j(y).val();
                            form_data['ts'][id]['options'][opt_id]['weight'] = j(y).attr('data_weight');
                        }else{
                            form_data['ts'][id]['options'][x] = {};//j(y).text();
                            form_data['ts'][id]['options'][x]['value'] = j(y).val();
                            form_data['ts'][id]['options'][x]['weight'] = j(y).attr('data_weight');
                        }
                    })
                }
                j.ajax({
                    type: "POST",
                    url: '/form_templates/field_settings/',
                    data: form_data,
                    success: function (data) {
                        var field_setting = j('#field_settings').clone().html();
                        var block_id = j('#field_settings #field_id').val();
                        j('#field_collection').append('<div class="field_form" id='+ block_id +'></div>');
                        j('#field_collection .field_form:last').append(field_setting);
                        j('#field_settings').html('');
                        var field_id = j('#field_id').clone();
                        j('#field_id').remove();
                        j('#field_collection').prepend(field_id);
                        j('#'+block_id).css('display','block');
                        j('#'+block_id).css('z-index','2000');
                        j('#'+block_id).css('visibility','visible');
                    }
                });
            }else{
                j('#field_id').val(id);
                var block_id = j('#field_collection #field_id').val();
                j('#'+block_id).css('display','block');
                j('#'+block_id).css('z-index','2000');
                j('#'+block_id).css('visibility','visible');
            }
        }
    });

    j('.drag_me').each(function(a,b){
        var pos = j(b).offset();
        var ele = j("<div />").appendTo(".template_element_selection");
        ele.attr('class','dragplaceholder');
        ele.attr('attr-data',j(b).attr('attr-data'));
        ele.css('left',pos['left']+'px');
        ele.css('top',pos['top']+'px');
    })
    // makes field selection visible
    j('.dragplaceholder').on('mousedown',function(e){
        switch(e.which){
            case 1:
                j(this).css('background-color','#a9b3bc');
        }
    });

    j('.dragplaceholder').on('mouseup',function(e){
        switch(e.which){
            case 1:
                j(this).css('background-color','');
                j(this).attr('style',initial_style.replace('background-color',''));
                options['field_type'] = j(this).attr('attr-data');
                if(drag_or_click == true){
                    drag_or_click = false;
                }else{
                    options['origin'] = 'dragplaceholder mouseup else';
                    ajax_call(options);
                }
        }
    });

    j('.dragplaceholder').on('mousemove',function(e){
        data = j(this).attr('attr-data');
        if(j('#template_drag_area').offset().top <= j(this).offset().top && j('#template_drag_area').offset().left <= j(this).offset().left){
            j('#template_drag_area').css('height','50px');
            j('#template_drag_area').css('color','transparent');
            j('#template_drag_area').css('line-height','0px');
            j(this).css('width',j('#template_drag_area').css('width'));
            j(this).css('height','50px');
            j('.dragplaceholder[attr-data='+data+']').css('opacity','0.2');
        }else{



            //j(this).next().css('opacity',0.2);

            j('.dragplaceholder[attr-data='+data+']').css('opacity','0.2');
            j('#template_drag_area').css('height','');
            j('#template_drag_area').css('color','');
            j('#template_drag_area').css('line-height','');
            j(this).css('width','')
            j(this).css('height','');
        }
    });


    clone = j('#inplace_drag_area').clone();
    j('.dragplaceholder').draggable({
        revert: true,
        helper: 'clone',
        cursor: "drag",
        connectToSortable: '#template_fields',
        drag: function(event,ui){
            //            if(j('#template_drag_area').offset().left <= ui.position.left && j('#template_drag_area').offset().top <= ui.position.top){
            //            if(j('#template_drag_area').offset().top <= j(this).offset().top && j('#template_drag_area').offset().left <= j(this).offset().left){
            if(dir == 'rtl'){
                if(j('#template_drag_area').offset().left + j('#template_drag_area').width() >= currentMousePos.x){
                    droppable_check = true;
                    var dragged = j(this);
                    if(j('#template_fields').find('#inplace_drag_area').length != 0){
                        j('#template_fields').find('#inplace_drag_area').remove();
                    }
                    j(this).attr('style',j('.ui-draggable-dragging').attr('style')+';height:50px;width:480px');
                    j('.dragplaceholder[attr-data='+j(this).attr('attr-data')+']').css('display','block');
                    j('.ui-draggable-dragging').css('display','none');
                    j('#template_fields').find('.ui-sortable-placeholder').after(clone);
                    j('#template_fields').find('#inplace_drag_area').attr('style','display:block;');
                }else{
                    droppable_check = false;
                    j(this).attr('style','');
                    j('.dragplaceholder[attr-data='+j(this).attr('attr-data')+']').css('display','');
                }
            }else{
                if(j('#template_drag_area').offset().left <= currentMousePos.x){
                    droppable_check = true;
                    var dragged = j(this);
                    if(j('#template_fields').find('#inplace_drag_area').length != 0){
                        j('#template_fields').find('#inplace_drag_area').remove();
                    }
                    j(this).attr('style',j('.ui-draggable-dragging').attr('style')+';height:50px;width:480px');
                    j('.dragplaceholder[attr-data='+j(this).attr('attr-data')+']').css('display','block');
                    j('.ui-draggable-dragging').css('display','none');
                    j('#template_fields').find('.ui-sortable-placeholder').after(clone);
                    j('#template_fields').find('#inplace_drag_area').attr('style','display:block;');
                }else{
                    droppable_check = false;
                    j(this).attr('style','');
                    j('.dragplaceholder[attr-data='+j(this).attr('attr-data')+']').css('display','');
                }
            }
            drag_or_click = true;
        },
        start: function(ui,event){
            if(initial_style == ''){
                initial_style = j(this).attr('style');
            }
        },
        change: function(ui,event){
        },
        stop: function(ui,event){
            if(!test_display_blank_form() && droppable_check){
                var dragged = j('#template_fields').find('.dragplaceholder');
                drag_or_click = true;
                options['field_type'] = j(this).attr('attr-data');//dragged.attr('attr-data');
                options['add_location'] = 'positioned';
                options['origin'] = 'dragplaceholder stop';
                ajax_call(options);
            }else{

            }

            j(this).attr('style',initial_style).css('background-color','');
            j('#template_fields').find('#inplace_drag_area').attr('style','');
        }
    });
    j('.dragplaceholder').on('mousedown',function(){
        initial_style = j(this).attr('style');
    })

    j('#template_drag_area').droppable({
        drop: function( event, ui ) {
            drag_or_click = true;
            options['field_type'] = ui.draggable.attr('attr-data');
            j('#template_drag_area').attr('style','');
            options['origin'] = 'template_drag_area droppable';
            ajax_call(options);
        }
    });



});

function activate_error_listing(){
    flag = false;
    j('#errorExplanation ul li').attr('style','display:none');
    j('#errors_pane').attr('style','');
    if(form_data['form_template']['name'] == ''){
        j('#name_error').attr('style','');
        flag = true;
    }
    if(form_data['form_template']['name'] == form_data_old['form_template']['name']){
        j('#template_error').attr('style','');
        flag = true;
    }
    if(flag){
        j('#errors_pane').attr('style','display:block');
    }else{
        j('#errorExplanation ul li').attr('style','');
    }
    return flag;
}

function add_new_option(){
    setTimeout(function(){
        var field_id = j('#field_id').val();
        var block = '#field_block_'+field_id;
        var copy_option_settings = j('#new_option_'+field_id).find('#settings').html();
        var add_more_link = j('#new_option_'+field_id).find('#ajax_link').html();
        var option_content = j('#new_option_'+field_id).find('#field_content');
        j('#new_option_'+field_id).html('');
        j('#new_option_'+field_id).parent().find('.add_option').html(add_more_link);
        if(j('#'+field_id+' .option_field').length > 0){
            j(copy_option_settings).insertAfter('#'+field_id+' .option_field:last');
        }else{
            j(copy_option_settings).insertBefore('#'+field_id+' .small-field');
        }
        if(j('#new_option_'+field_id).attr('attr_type') == 'select'){
            if(j(block+' select')[0].options.length){
                j(option_content.html()).insertAfter(block+ ' option:last');
            }else{
                j(block+ ' select').append(option_content.html());
            }
        }else{
            if(j(block+' .input_text_field').length > 0){
                j(option_content.html()).insertAfter(block+ ' .input_text_field:last');
            }else{
                j(option_content.html()).insertAfter(block+ ' .label_text_field');
            }

            j('#'+field_id+' .option_right .small-field :input').each(function(a,b){
                j(b).attr('attr_no',a);
            });
            j('#'+field_id+' .option_right .smaller-field :input').each(function(a,b){
                j(b).attr('attr_no',a);
            });
        }
    },1000);
}

function after_add_call(){
    j('#template_drag_area').css('height','');
    j('#template_drag_area').css('width','');
    j('#template_drag_area').css('color','');
    j('#template_drag_area').css('line-height','');
    new_id = j('#dragged_fields').find('.field_block').attr('id');
    var new_field = j('#dragged_fields').html();
    if(options['add_location']!='positioned'){
        j(new_field).appendTo('#template_fields');
    }else{
        j('#template_fields').find('.dragplaceholder').attr('id','remove_it');
        j('#template_fields').find('.dragplaceholder').after(new_field);
        j('#remove_it').remove();
    }
    j('.template_element_selection .dragplaceholder').css('background-color','');
    display_blank_form();
    j('.field_set').find('input, textarea, select').each(function(a,b) {
        j(b).attr('disabled','');
        j(b).css('background-color','#fff');
    });
    j('#template_fields').sortable();
    j('#dragged_fields').html('');
    options = [];
}

function ajax_call(options){
    if(options.hasOwnProperty('field_type')){
        j.ajax({
            type: "POST",
            url: '/form_templates/add_field/' + options['field_type'] ,
            beforeSend: function(){
                j('.overlay').css('z-index','9999');
                j('.overlay').css('display','block');
            },
            success: function (data) {
                after_add_call();
                setTimeout(function(){
                    j('.overlay').css('z-index','');
                    j('.overlay').css('display','');
                },500);
            }
        });
    }else{
}
}

function change_tab(ele){
    j('.template_element_selection > .tabs > ul > li').each(function(a,b){
        j(b).removeClass('active_tab');
        tab_name = j(b).attr('attr-data');
        j('.'+tab_name+'_tab').attr('style','display:none');
        if(ele.attr('attr-data') == 'field_settings'){
            j('.dragplaceholder').css('z-index','-1000');
        }
        else{
            j('.dragplaceholder').css('display','');
            j('.dragplaceholder').css('z-index','');
        }
    });
    ele.addClass('active_tab');
    j('.'+ele.attr('attr-data')+'_tab').attr('style','');
}

function display_blank_form(){
    var eles = j('#template_fields').find('div.field_block[_delete!='+1+']');
    if(eles.length > 0){
        j('.template_blank_form').attr('style','display:none');
    }else{
        j('.template_blank_form').attr('style','');
    }
}

function test_display_blank_form(){
    return j('#template_fields').find('div.field_block[_delete!='+1+']').length == 0 ? true : false;
}