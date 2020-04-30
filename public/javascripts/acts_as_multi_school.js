var j= jQuery.noConflict();
function get_partial(){
    var link = this;
    j('.nav-vertical a.active').removeClass('active');
    j(link).addClass('active');
    j('.detail-list').html("<label>Loading...</label>");
    j('.detail-list').load(this.href,null,function(resp,status,xhr){
        if(status=="error"){
            var msg = "Sorry but there was an error: ";
            j(".detail-list").html(msg);
        }
    });
    return false;
}
function focus_grid_cell(){
    if(this.checked){
        this.parentElement.classList.add('red-border');
        this.parentElement.classList.add('plugin-cell-active');
    }else{
        this.parentElement.classList.remove('red-border');
        this.parentElement.classList.remove('plugin-cell-active');
    }
}
function set_active_link(){
    j('.ul-nav a').each(function(i,el){
        if(el.pathname == document.location.pathname)
            el.classList.add("active")
    });
}

function ajax_post(form,path){
    j.post(path, j(form).serialize(), function(data){
        j(form).parentElement.html(data);
    }).success(console.log("Done")).error(console.log("Not Done"));
    return false;
}


j(function(){
    j(document).ajaxStart(function() {
        j('body').addClass('waiting')
        });
    j(document).ajaxStop(function() {
        j('body').removeClass('waiting')
        });
    Ajax.Responders.register({
        onCreate: function() {
            j('body').addClass('waiting')
        },
        onComplete: function() {
            j('body').removeClass('waiting')
        }
    });
    set_active_link();
    j.ajaxSetup ({
        cache: false
    });
    j('.nav-vertical a').bind('click',get_partial);
    j('.nav-vertical a.non-partial').unbind('click',get_partial);
    j('.plugin-cell input[type="checkbox"]').bind('change',focus_grid_cell);
    j('.plugin-cell input[type="checkbox"]').trigger('change');
    j("#select_all_plugin").click(function(){
      j('.plugin-cell input').each(function(i,e){if(!e.checked) j(e).trigger('click');})
      return false;
    });
    j("#select_no_plugin").click(function(){
      j('.plugin-cell input').each(function(i,e){if(e.checked) j(e).trigger('click');})
      return false;
    });
});
