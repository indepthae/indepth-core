function render_generic_hook(hooks){

    var hooked_link, target, link, hlink;
    hooks.each(function(hook){
        if(hook['active'] !== undefined && hook['active'] == false){

        }else{
            hlink = '/'+hook['destination']['controller']+'/'+hook['destination']['action']+(j.isNumeric(hook['id']) ? '/'+hook['id'] :'')
            link = j('<a>',{
                'text': hook['title']
            });
            if(hook['ajax'] !== undefined && hook['ajax']){
                link.attr('href','#').attr('onclick',"new Ajax.Request('"+hlink+"', {asynchronous:true, evalScripts:true}); return false;");
            }else{
                link.attr('href', hlink);
            }
            if(hook["target_id"] !== undefined && hook["target_id"] == 'inner-tab-menu'){ // "inner-tab-menu"
                hooked_link = j('<li>',{
                    'class': 'themed_bg',
                    'html' : link.prop('outerHTML')
                }).addClass('themed-dark-hover-background');
                target = j('#'+hook["target_id"]).children('ul');
                if(hook["location_order"] !== undefined){
                    hook["location_order"] == "first" ? j(target).prepend(hooked_link):(hook["location_order"] == "last" ? j(target).children('li:last-child').after(hooked_link): j(target).children('li:nth-child('+hook["location_order"]+')').before(hooked_link));
                }else{
                    //j(target).children('li:first-child');
                    j(target).prepend(hooked_link);
                }
            }else{ // link box
                link = j("<a>",{
                    'href':'/'+hook['destination']['controller']+'/'+hook['destination']['action'],
                    'text': hook['title']
                });
                hooked_link = j('<div>',{
                    'class': 'link-box',
                    'html': j('<div>',{
                        'class': 'link-heading',
                        'html': link.prop('outerHTML')
                    }).prop('outerHTML')+j('<div>',{
                        'class': 'link-descr',
                        'text': hook['description']
                    }).prop('outerHTML')
                })
                target = j('.box').find(hook['inner_target']);
                if(hook["location_order"] !== undefined){
                    hook["location_order"] == "first" ? j(target).prepend(hooked_link):(hook["location_order"] == "last" ? j(target).children('.link-box:last-child').after(hooked_link): j(target).children('.link-box:nth-child('+hook["location_order"]+')').before(hooked_link));
                }else{
                    (target.length > 0) ? j(target).prepend(hooked_link) : j('.box').append(hooked_link);
                }
            }   
        }        
    });

}
