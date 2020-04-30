var j = jQuery.noConflict();
j(document).ready(function(){
    if(j('#infinite-scrolling').size() > 0)
        return j(window).on('scroll', function (e){
            var more_posts_url;
            more_posts_url = j('#infinite-scrolling').find(".pagination").find(".next_page").attr('href');
            if(more_posts_url && (j(window).scrollTop() > j(document).height() - j(window).height() - 1)){
                j('.pagination').html('<img src="/images/loader.gif" alt="Loading..." title="Loading..." />');
                j.getScript(more_posts_url);
            }
            return;
        });

});