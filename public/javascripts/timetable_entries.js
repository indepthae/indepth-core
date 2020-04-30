j(document).delegate('.tt-subject','mouseenter',function(){
    TOP = 'top';
    BOTTOM = 'bottom';
    j(this).children('.class_timings').children('.cross_section').removeClass('inactive_div');
    var column = document.createElement('div').addClassName("col");
    var parent = j(this).parents('.td');
    var table = j('#table-viewer');
    var tooltip = j(this).children('.class_timing_tooltip').css('display','block');
    var subjects = j(tooltip).find('.subject1');
    var table_height= j(table).height();
    var table_width = j(table).outerWidth();
    var table_top = j(table).position().top;
    var table_left = j(table).position().left;
    var table_right = table_left + table_width;
    var cell_height = j(parent).height();
    var cell_width = j(parent).width();
    var cell_top = j(parent).position().top;
    var cell_left = j(parent).position().left;
    var tooltip_height = j(tooltip).height();
    var tooltip_width = j(tooltip).outerWidth();
    var ht = height_top = cell_top - table_top - 25;
    var hb = height_bottom = (table_top + table_height) - (cell_top + cell_height) - 25;
    var wl = width_left = cell_left - table_left - 10;
    var wr = width_right = (table_left + table_width) - (cell_left + cell_width) - 10;
    var max_width = Math.max(wl,wr);
    var max_height = Math.max(ht,hb);
    var valign = max_height == hb ? BOTTOM : TOP;
    if(j(tooltip).attr('data-cache') === undefined){ //
        if(tooltip_height > max_height){ // data overflow in tooltip
            var tooltip_width_a = 0;
            var left,atop, col = j(column).clone();
            var c_height, height_c = 30;
            blocks = j(tooltip).find('.block');
            block_width = blocks.first().outerWidth();
            var cnt = blocks.length;
            tooltip_width_a = block_width; //tooltip_width;
            j(blocks).each(function(a,b){ // grouping subject blocks
                c_height = j(b).outerHeight();
                if(height_c + c_height > max_height){
                    height_c = c_height+30;
                    tooltip_width_a += block_width;
                    subjects.append(col);
                    col = j(column).clone();
                    j(col).append(b);
                }else{
                    height_c += c_height;
                    col.append(b);
                }
                if((a+1)==cnt)
                    subjects.append(col);
            });

            if(tooltip_width_a > table_width - 20 || tooltip_width_a > max_width){
                j(subjects).css('width',tooltip_width_a);
                tooltip_width_a = max_width < table_width - 20 && tooltip_width_a > table_width ? table_width - 50 : (tooltip_width_a + 20 > table_width ? table_width - 50 : tooltip_width_a);
                j(tooltip).css('width', tooltip_width).css('overflow-x','auto').css('overflow-y','hidden');
            }

            if(max_height < tooltip_height){
                j(tooltip).css('height',max_height);
                j(subjects).css('max-height',max_height-30);
            }
            tooltip_width = j(tooltip).css('width',tooltip_width_a).outerWidth();
            tooltip_height = j(tooltip).height();

            cols = j(tooltip).find('.col');
            cols.first().addClass('no_border');
            cols.css('height',Math.max.apply(null,cols.map(function() {
                return j(this).height()
                }).get())-20);

        }

        left = cell_left + 20;
        new_left = left+tooltip_width;
        extra = (left + tooltip_width - table_right);
        cell_left_gap = cell_left - table_left;

        left += (new_left == table_right) ? (tooltip_width - 10) : ((new_left > table_right && extra > 0) ? -(extra-cell_left_gap >= 0 ? (extra-cell_left_gap+10) : extra+10 ): 0);
        
        atop = (valign == TOP ? cell_top-tooltip_height - 8 : cell_top + 100);
        if(atop+tooltip_height > table_height+table_top && valign == BOTTOM)
            atop = atop - ((atop+tooltip_height) - (table_height+table_top));

        j(tooltip).css('display','block').offset({
            'top': atop,
            'left': left
        }).attr('data-cache',true);
    }else{
        j(tooltip).css('display','block');
    }
});

j(document).delegate('.tt-subject','mouseleave',function(){
    j(this).children('.class_timings').children('.cross_section').addClass('inactive_div');
    j(this).children('.class_timing_tooltip').css('display','none');
});

j(document).delegate('.cross_section','mouseenter',function(){
    j(this).addClass('red_back');
});
j(document).delegate('.cross_section','mouseleave',function(){
    j(this).removeClass('red_back');
});
function remove_entry(){
    j('.cancelled').click(function(){j(this).parent().remove();});
}
