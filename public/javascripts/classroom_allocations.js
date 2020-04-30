var allocation_type,selected_tt,month_year;
var timetable,timetable_swaps,batches,all_batches,batch_subjects,employees,timings,allocated_class,weekday,classroom_allocations,class_rooms,elective_subjects,emp_subjects,ele_emp_subjects;
var sub,selected_day,prefix,start,end,classroom_id,sname,sub_id,e_id,ename,id_attr,x,originalBg, allocation_box;
var cname,drag_element,search_batches = {},dir;
var test, current_date,flag;
var cancelled_text_translation, no_timetable_warning_message, this_timetable_swap;

function getjson(val,type) {
    // fetching data required for weekly allocation
    if ( type == "weekly") {
        $('loader2').show();
        allocation_type = type;
        selected_tt = val[0];
        new Ajax.Request('/classroom_allocations/weekly_allocation.json',{
            parameters: {
                timetable_id: val,
                alloc_type: type
            },
            asynchronous:true,
            evalScripts:true,
            method:'get',
            onComplete:function(resp){
                j('#loader2').hide();
                allocationBuilder(resp.responseJSON);
            }
        });
    }
    // fetching data for data specific allocation
    else if (type == "date_specific"){
        $('loader').show();
        allocation_type = type;
        month_year = val[0]+'-'+val[1];
        selected_day = 0;
        new Ajax.Request('/classroom_allocations/date_specific_allocation.json',{
            parameters: {
                date: month_year,
                alloc_type: type
            },
            asynchronous:true,
            evalScripts:true,
            method:'get',
            onComplete:function(resp){
                j('#loader').hide();
                allocationBuilder(resp.responseJSON);
            }
        });
    }
}


function allocationBuilder(respjson){
    test = respjson;
    timetable = respjson.timetable_entries;
    timetable_swaps = respjson.timetable_swaps;
    batches = respjson.batches;
    all_batches = batches;
    batch_subjects = respjson.subjects;
    employees = respjson.employees;
    timings = respjson.classtimings;
    allocated_class= respjson.allocated_classrooms;
    weekday = respjson.days;
    classroom_allocations = respjson.classroom_allocations;
    class_rooms = respjson.classrooms
    elective_subjects = respjson.elective_subjects
    emp_subjects = respjson.emp_subjects
    ele_emp_subjects = respjson.elective_emp_subjects;
    cancelled_text_translation = respjson.cancelled_text;
    no_timetable_warning_message = respjson.no_timetable_warning;
    //  Header

    var header = drawHeader(); // Draw header
    j('.allocations').html(header);

    j('li.days a').hover(
        function() {
            j( this ).addClass( "themed_text" );
        },function() {
            j( this ).removeClass( "themed_text" );
        }
        );   // changing day name to theme color on hover

    addListScroller(); // attaching slider for date specific

    j("#my-als-list").als({
        visible_items: 7,
        scrolling_items: 7,
        orientation: "horizontal",
        autoscroll: "yes",
        interval: 60000000,
        speed: 400,
        easing: "linear",
        direction: "right",
        start_from: 7
    });

    if (allocation_type == "weekly"){
        selected_day = weekday[0][0];
        j('.days a#'+selected_day).addClass("active_day").addClass("themed_text");
    }
    else{
        j('.days a#0').addClass("active_day").addClass("themed_text");
    }  // setting theme color for active day


    //Allocation box
    allocation_box = document.createElement('div').addClassName("alloc_box");
    var box = drawBox();
    j(allocation_box).html(box);
    j('.allocations').append(allocation_box);
    //    drawEmptyBox();
    makeDroppable();

    // Buildings & Rooms

    renderRooms();

    // Search batch
    j(".batch_search").on({
        "keypress": function(){
            searchBatches();
        },
        "keyup": function(){
            searchBatches();
        },
        "change": function(){
            searchBatches();
        }
    })

}

function drawHeader(){
    var header = document.createElement('div').addClassName("header");
    var search = document.createElement('div').addClassName("search");
    var weekdays = document.createElement('div').addClassName("weekdays");
    var days = document.createElement('li').addClassName("days");
    var day = document.createElement('a').addClassName("day");

    var search_box = document.createElement('input').addClassName("batch_search");
    j(search_box).attr({
        type: "text",
        id: "search",
        placeholder: search_batch,
        size: "16",
        maxlength: "64"
    });

    var month = document.createElement('div').addClassName("show_month");
    j(search).append(search_box);
    j(header).append(search);

    if (allocation_type == "date_specific") month.textContent =  month_names[(new Date(month_year + "-01")).getMonth()] + ' ' + (new Date(month_year + "-01")).getUTCFullYear();
    if (allocation_type == "weekly") {
        j(search).css({
            "border": "0px"
        });
    }
    j(header).append(weekdays);
    j(search).append(month);

    for (var i = 0; i < weekday.length ; i++){
        if (allocation_type == "weekly"){
            weekday_text=weekday[i][1];
            weekday_id=weekday[i][0];
        }
        else{
            weekday_text=weekday[i];
            weekday_id=i;
        }

        var d =  j(day).clone().text(weekday_text);
        j(d).attr({
            "id":weekday_id,
            "class":"day"
        });
        var ds = j(days).clone().html(d);
        ds.appendTo(weekdays);
        j(d).click(function(){
            showAllocationForDay(this);
        })
    }
    return header;

}

function addListScroller(){
    if ( allocation_type == "date_specific") {
        j('.days').addClass("als-item");
        j('.weekdays').addClass("als-wrapper");

        var als_container = document.createElement('div').addClassName("als-container");
        j(als_container).attr({
            id: "my-als-list"
        });

        j('.weekdays').wrap(als_container);

        var span_prev = document.createElement('span').addClassName("als-prev");
        j(span_prev).insertBefore( ".weekdays" );
        j(span_prev).append("<div class='clickable1'></div>")

        var als_viewport = document.createElement('div').addClassName("als-viewport");
            j('.als-wrapper').wrap(als_viewport);

        var span_next = document.createElement('span').addClassName("als-next");
        j(span_next).insertAfter(".als-viewport");
        j(span_next).append("<div class='clickable2'></div>")
        }
    }



function showAllocationForDay(obj){
    j('.alloc_box').addClass("transparency");
    var loader_src = j('#loader1')[0].src;
    j('.allocations').append("<img src=" + loader_src +"align = 'absmiddle' border = '0'  style = 'display:none' id ='loader3'></img><span id= 'loading_text'>Loading...</span>")
    j('.days a.active_day').removeClass('active_day').removeClass("themed_text").addClass('day')
    j(obj).removeClass("day").addClass("active_day").addClass("themed_text");
    selected_day = j(obj).attr('id');
    j('#loader3').show();

    j.get('/classroom_allocations/find_allocations', function(result) {
        allocated_class = result.allocations;
        classroom_allocations = result.classroom_alloc;
        j('#loader3').hide();
        j('#loading_text').remove();
        j('.alloc_box').removeClass("transparency");
        var box = drawBox();
        j(allocation_box).html(box);
        //        drawEmptyBox();
        makeDroppable();
    })
}


function drawBox(){
    var box = document.createElement('div').addClassName("box");
    var section = document.createElement('div').addClassName("section");
    var batch_name = document.createElement('div').addClassName("name themed_text");
    var batch_text = document.createElement('div').addClassName("batch_text");
    var subjects = document.createElement('div').addClassName("subjects");
    var sub_name = document.createElement('div').addClassName("sub");
    var sub_text = document.createElement('div').addClassName("sub_text");
    var emp_text = document.createElement('div').addClassName("emp_text");
    var cancelled_text = document.createElement('span').addClassName("cancelled_text");
    var allotment_status = document.createElement('div').addClassName('allotment-status');
    var tooltip_content = document.createElement('div').addClassName("tt_content");

    for (var key in batches){
        var sec = j(section).clone();
        var batch = j(batch_name).clone();
        var bt = j(batch_text).clone().text(batches[key]);
        sub = j(subjects).clone();
        var flag;
        test.tt.each(function(c){
            timetable[key].select(function(s){
                var dd = String(parseInt(selected_day) + 1);
                if (dd.length == 1) dd = "0" + dd;
                allocation_type == "weekly" ? condition = 1 : condition = ((month_year + "-" + dd ) >= c.timetable.start_date && (month_year + "-" + dd ) <= c.timetable.end_date && s.timetable_entry.batch_id == key && c.timetable.id == s.timetable_entry.timetable_id );
                //(c.timetable.id == s.timetable_entry.timetable_id && (parseInt(selected_day) + 1 >= new Date(c.timetable.start_date).getDate() && parseInt(selected_day) + 1 <= new Date(c.timetable.end_date).getDate()) );
                if (condition){
                    if (allocation_type == "date_specific" ){
                        d = month_year + '-' + dd;
                        current_date = d;
                        var selected_day1 = new Date(Date.parse(d)).getDay();
                    }
                    else{
                        var selected_day1 = selected_day;
                    }
                    if (s.timetable_entry.weekday_id == selected_day1) {
                        var sub_details={};
                        var emp_details,ele_emp_details,emps;
                        var tte_id = s.timetable_entry.id;
                        j(sec).attr("id",key);
                        j(batch).append(bt);
                        j(sec).append(batch);
                        j(sec).append(sub);
                        j(box).append(sec);

                        batch_subjects[key].select(function(y){
                            if((y.subject.id == s.timetable_entry.entry_id && s.timetable_entry.entry_type == "Subject") || (y.subject.elective_group_id == s.timetable_entry.entry_id && s.timetable_entry.entry_type == "ElectiveGroup"))
                            {
                                if(allocation_type == "date_specific"  && s.timetable_entry.entry_type == 'Subject'){
                                    if(Object.keys(timetable_swaps).indexOf((s.timetable_entry.id).toString()) > -1){
                                        this_timetable_swap = j.grep(timetable_swaps[s.timetable_entry.id], function(e){ console.log(e); console.log(e.timetable_swap.date); return e.timetable_swap.date == current_date });
                                        this_timetable_swap = this_timetable_swap[0];
                                    }else{
                                        this_timetable_swap = undefined;
                                    }
                                    if(this_timetable_swap !== undefined && !this_timetable_swap.timetable_swap.is_cancelled){ // not a cancelled swap
                                        sub_details[y.subject.id] = j.grep(batch_subjects[key], function(e){ return e.subject.id == this_timetable_swap.timetable_swap.subject_id; })[0].subject.name;
                                    }else{
                                        sub_details[y.subject.id] = y.subject.name;
                                    }
                                }else{
                                    sub_details[y.subject.id] = y.subject.name;
                                }
                            }
                        });

                        emp_details = emp_subjects;
                        ele_emp_details = ele_emp_subjects;
                        test.classtimings.select(function(t){
                            if (t.class_timing.id == s.timetable_entry.class_timing_id) {
                                var st = new Date(t.class_timing.start_time);
                                prefix = st.getUTCHours() >= 12 ? 'pm' : 'am'
                                start = parseFloat(st.getUTCHours() +"."+ st.getUTCMinutes()).toFixed(2) + prefix;
                                var et = new Date(t.class_timing.end_time);
                                prefix = et.getUTCHours() >= 12 ? 'pm' : 'am'
                                end = parseFloat(et.getUTCHours() +"."+ et.getUTCMinutes()).toFixed(2) + prefix;
                            }
                        });

                        var classroom = {};
                        var classroom_ids = {};
                        var allocation_dates = {}

                        if(s.timetable_entry.entry_type == "Subject"){
                            classroom[s.timetable_entry.entry_id] = [];
                            classroom_ids[s.timetable_entry.entry_id] = [];
                        }else{
                            j.each(elective_subjects[s.timetable_entry.entry_id],function(index, value){
                                classroom[value] = [];
                                classroom_ids[value] = [];
                            });
                        }

                        if (allocation_type == "date_specific"){
                            j.each(sub_details, function( index, value ) {
                                classroom[index] = {};
                                classroom_ids[index] = {};
                            })

                            for(day = 1; day <= 31 ; day++){
                                if (String(day).length == 1) {
                                    day = "0" + String(day)
                                };

                                if(s.timetable_entry.entry_type == "Subject"){
                                    classroom[s.timetable_entry.entry_id][month_year + "-" + day] = [];
                                    classroom_ids[s.timetable_entry.entry_id][month_year + "-" + day] = [];
                                }else{
                                    j.each(elective_subjects[s.timetable_entry.entry_id],function(index, value){
                                        classroom[value][month_year + "-" + day] = [];
                                        classroom_ids[value][month_year + "-" + day] = [];
                                    });
                                }
                            }
                        }
                        else{
                            j.each(sub_details, function( index, value ) {
                                classroom[index] = [];
                                classroom_ids[index] = [];
                            })
                        }

                        allocated_class.select(function(c){
                            if (c.allocated_classroom.timetable_entry_id == s.timetable_entry.id){
                                if (allocation_type == "date_specific" && c.allocated_classroom.date != nil){
                                    class_rooms.select(function(cr){
                                        if (cr.classroom.id == c.allocated_classroom.classroom_id){

                                          if (typeof(classroom[c.allocated_classroom.subject_id]) == "undefined"){
                                            classroom[c.allocated_classroom.subject_id]=[];

                                          }
                                          if (typeof(classroom_ids[c.allocated_classroom.subject_id]) == "undefined"){
                                            classroom_ids[c.allocated_classroom.subject_id]=[];
                                          }

                                            classroom[c.allocated_classroom.subject_id][c.allocated_classroom.date].push(cr.classroom.name);
                                            classroom_ids[c.allocated_classroom.subject_id][c.allocated_classroom.date].push(cr.classroom.id);

                                        }
                                    })
                                }
                                else if (allocation_type == "weekly" && c.allocated_classroom.date == nil){
                                    class_rooms.select(function(cr){
                                        if (cr.classroom.id == c.allocated_classroom.classroom_id){

                                          if (typeof(classroom[c.allocated_classroom.subject_id]) == "undefined"){
                                            classroom[c.allocated_classroom.subject_id]=[];

                                          }
                                          if (typeof(classroom_ids[c.allocated_classroom.subject_id]) == "undefined"){
                                            classroom_ids[c.allocated_classroom.subject_id]=[];
                                          }
                                          
                                            classroom[c.allocated_classroom.subject_id].push(cr.classroom.name);
                                            classroom_ids[c.allocated_classroom.subject_id].push(cr.classroom.id);
                                        }
                                    })
                                }
                            }
                        });
                        var flag = 0,eflag = 0;
                        j.each(sub_details, function( index, value ) {
                            flag = flag + 1;
                            sname = value;
                            sub_id = index;
                            if(s.timetable_entry.entry_type == "Subject"){
                                if(allocation_type == "date_specific" && this_timetable_swap !== undefined && !this_timetable_swap.timetable_swap.is_cancelled){
                                    //emps = j.grep(employees,function(e){ return e.employee.id == this_timetable_swap.employee_id });
                                    emps = j.map(employees,function(e){return ((e.employee.id == this_timetable_swap.timetable_swap.employee_id) ? e.employee.first_name + ' ' + e.employee.last_name : '');}).filter(String);
                                }else{
                                    emps = emp_details[tte_id];
                                }
                            }else{
                                emps = ele_emp_details[index];
                            }
                            if(emps == undefined){
                                ename = no_teacher;
                            }else{
                                //                                console.log(emps[0]);
                                enames = emps; //(s.timetable_entry.entry_type == "Subject" ? emp_details[tte_id]:ele_emp_details[index]);
                                max_name_length = 12;
                                names_count = enames.length;
                                if(names_count > 1){
                                    //console.log(emps);
                                    ename = [];
                                    j.each(enames,function(a,b){
                                        prefix_length = (names_count > a+1) ? ((" + " + (names_count - a - 1).toString()).length) : 0;
                                        if(b.length <= (max_name_length - ename.join(", ").length - prefix_length)){
                                            ename.push(b.trim());
                                        }else{
                                            if(a == 0)
                                                ename.push(shorten_string(enames[0], max_name_length));
                                            eflag = a;
                                            return false;
                                        }
                                    });
                                    ename = ename.join(', ');
                                    if(eflag >= 0)
                                        ename += ' + '+(names_count - eflag);

                                }else{
                                    ename = shorten_string(enames[0], max_name_length);
                                }
                            }

                            //                            flag > 1 ?  id_attr = s.timetable_entry.id + flag : id_attr = s.timetable_entry.id;
                            id_attr = s.timetable_entry.id;
                            var m = j(sub_text).clone().text(sname);
                            var n = j(emp_text).clone().text(ename);
                            var l = j(allotment_status).clone();
                            x = j(sub_name).clone();
                            j(x).append(m);
                            j(x).append(n);
                            if(allocation_type == "date_specific" && this_timetable_swap !== undefined && this_timetable_swap.timetable_swap.is_cancelled){
//                            if(allocation_type == "date_specific" && timetable_swaps[s.timetable_entry.id] !== undefined && timetable_swaps[s.timetable_entry.id].timetable_swap.is_cancelled){
                                c_t = j(cancelled_text).clone().text(cancelled_text_translation);
                                j(x).addClass('cancelled');
                                j(x).append(c_t);
                            }
                            j(x).append(l);
                            //                            j(x).hover(
                            //                                function () {
                            //                                    originalBg =j(this).css("background-color");
                            //                                    j(this).css({
                            //                                        'background-color' : '#ffffcd'
                            //                                    });
                            //                                },
                            //                                function () {
                            //                                    j(this).css({
                            //                                        'background-color' : originalBg
                            //                                    });
                            //                                }
                            //                                );


                            j(x).attr({
                                "id": 'sub' + id_attr + '_' + sub_id
                            });
                            var subtooltip = "<div class='tooltip subtooltip'><div class='timing'>"+ start + " - " + end + "</div>" + "<div class='sub_text1'>" + sname +"</div>"
                            if (emps != undefined){
                                emps.each(function(e,i){
                                    subtooltip = subtooltip + "<div class='emp_text1'>"+ (i+1) + ". " + e + "</div>"
                                })
                            }
                            else{
                                subtooltip = subtooltip + "<div class='emp_text1'>" + no_teacher + "</div>"
                            }


                            subtooltip = subtooltip + "</br>"
                            j(x).data("info",{
                                "sname": sname,
                                "ename": ename,
                                "start":start,
                                "end":end ,
                                "classroom_id": classroom_ids,
                                "batch_id": key,
                                "emp_id": e_id,
                                "sub_id": sub_id,
                                "weekday_id": selected_day,
                                "class_timing_id": s.timetable_entry.class_timing_id,
                                "tte_id": s.timetable_entry.id
                            });
                            j(x).data({
                                "date" : current_date
                            })
                            j.each(classroom,function(key,el){
                                if (key == sub_id && el[current_date] != undefined && allocation_type == "date_specific"){
                                    el[current_date].each(function(e,i){

                                        subtooltip = subtooltip + "<div class='room_name'" + "id=" + classroom_ids[key][current_date][i] + ">" + "<span id= 'rname' >" +e + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>"
                                    });
                                }
                                if (key == sub_id && allocation_type == "weekly"){
                                    el.each(function(e,i){
                                        subtooltip = subtooltip + "<div class='room_name'" + "id=" + classroom_ids[key][i] + ">" + "<span id= 'rname' >" +e + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>"
                                    });
                                }
                            });

                            subtooltip = subtooltip + "</div"
                            j(this).children('.arrow_box').css({
                                "display": "none"
                            });

                            j(x).append(subtooltip);
                            j(x).mouseover(function(){
                                j(this).children('.subtooltip').removeAttr('style').show();
                                j(this).children('.subtooltip').show();
                                ele_pos = j(this).position();
                                ele_width = j(this).outerWidth();
                                ele_height = j(this).outerHeight();
                                box_pos = j('.alloc_box').position();
                                box_width = j('.alloc_box').outerWidth();
                                box_height = j('.alloc_box').outerHeight();
                                child = j(this).children('.subtooltip');
                                child_width = j(child).outerWidth();
                                if (dir == 'rtl'){
                                    if(j(child).hasClass('tooltip')){ // normal case
                                        child.css('left',ele_pos.left+ele_width-child_width).css('position','absolute').css('top',ele_pos.top+50);
                                    }

                                    if (box_pos.top  + box_height < (ele_pos.top + ele_height + 155)){ //console.log('case 2');
                                        child_height = j(child).outerHeight();
                                        child.addClass("arrow_box")
                                        .removeClass("tooltip")
                                        .removeClass('tooltip_case').css('left',ele_pos.left+ele_width-child_width).css('top',ele_pos.top-child_height).css('position','absolute');
                                    }

                                    // right side shortage case
                                    if(ele_pos.left < (box_pos.left + box_width) && ((box_pos.left + box_width) < (ele_pos.left + ele_width))){ // right shortage
                                        if(j(child).hasClass('arrow_box')){
                                            child.css('left',ele_pos.left-child_width+85).css('position','absolute');
                                        }else{
                                            child.css('left',ele_pos.left-child_width+20).css('position','absolute');
                                        }
                                    }

                                }
                                else{
                                    if (box_pos.left  + box_width < (ele_pos.left + ele_width + 155)){ //console.log('case 1');
                                        j(this).children('.subtooltip').addClass("tooltip_case").removeClass("tooltip")
                                    }

                                    if (box_pos.top  + box_height < (ele_pos.top + ele_height + 155)){ //console.log('case 2');
                                        j(this).children('.subtooltip').addClass("arrow_box")
                                        .removeClass("tooltip")
                                        .removeClass('tooltip_case');
                                    }
                                    if (box_pos.left  + box_width < (ele_pos.left + ele_width + 155) &
                                        box_pos.top  + box_height < (ele_pos.top + ele_height + 155)){ //console.log('case 3');
                                        j(this).children('.subtooltip').addClass("arrow_box")
                                        .removeClass("tooltip")
                                    }
                                    tooltip_height = j(this).children('.subtooltip').outerHeight();
                                    top_diff = ele_pos.top - box_pos.top;
                                    bottom_diff = box_pos.top + box_height - ele_pos.top;
                                    if((top_diff < tooltip_height) || (bottom_diff < tooltip_height && bottom_diff > 0)){
                                        if(!j(this).children('.subtooltip').hasClass('tooltip_case') && !j(this).children('.subtooltip').hasClass('tooltip')){//
                                            j(this).children('.subtooltip').css('margin-top',0).css('position','relative');
                                            tooltip_position_diff = j(this).children('.subtooltip').position().top - ele_pos.top;
                                            j(this).children('.subtooltip').css('top',ele_pos.top-tooltip_height).css('position','absolute').css('left',ele_pos.left);
                                        }
                                    }
                                    if(j(this).children('.subtooltip').hasClass('arrow_box')){
                                        tooltip_height = j(this).children('.subtooltip').outerHeight();
                                        j(this).children('.subtooltip').css('left',ele_pos.left).css('top',ele_pos.top-tooltip_height).css('position','absolute').css('margin-top',0);
                                    }
                                    if(ele_pos.left < box_pos.left){ // left shortage // 155 - 20
                                        if(j(this).children('.subtooltip').hasClass('tooltip')){
                                            j(this).children('.subtooltip').css('left',ele_pos.left+90) // set left position
                                            .css('position','absolute') // set positioning
                                            .css('margin-left',0) // reset left margin
                                            .css('top',ele_pos.top+40); // set top position
                                        }else if(j(this).children('.subtooltip').hasClass('arrow_box')){
                                            j(this).children('.subtooltip')
                                            .css('left',ele_pos.left+29) // set left position
                                            .css('position','absolute') // set positioning
                                            .css('margin-left',0); // reset left margin
                                        }else{
                                            j(this).children('.subtooltip')
                                            .css('left',ele_pos.left+137)
                                            .css('position','absolute') // set positioning
                                            .css('margin-left',0); // reset left margin
                                        }
                                    }
                                    if(ele_pos.left < (box_pos.left + box_width) && ((box_pos.left + box_width) < (ele_pos.left + ele_width))){ // right shortage
                                        if(j(this).children('.subtooltip').hasClass('arrow_box')){
                                            j(this).children('.subtooltip')
                                            .removeClass('arrow_box')
                                            .addClass('tooltip');
                                        }
                                        if(j(this).children('.subtooltip').hasClass('tooltip')){
                                            j(this).children('.subtooltip')
                                            .removeClass('tooltip')
                                            .addClass('tooltip_case')
                                            .css('top',ele_pos.top+50); // set top position
                                        }
                                        j(this).children('.subtooltip').css('left',ele_pos.left-135)
                                        .css('position','absolute') // set positioning
                                        .css('margin-left',0);
                                    }

                                }

                                j('.sub').mouseleave(function(){
                                    j(this).children('.subtooltip').removeAttr('style');
                                });
                                j(this).children('.subtooltip').mouseleave(function(){
                                    j(this).removeAttr('style').addClass('tooltip')
                                           .removeClass('tooltip_case')
                                           .remove('arrow_box');
                                });
                            });

                            j(sub).append(x);

                            allocated_class.select(function(c){
                                if (c.allocated_classroom.timetable_entry_id == s.timetable_entry.id && c.allocated_classroom.subject_id == sub_id ){
                                    if (allocation_type == "date_specific" && c.allocated_classroom.date != nil &&
                                        c.allocated_classroom.date == current_date){
//                                        (timetable_swaps[s.timetable_entry.id] !== undefined && timetable_swaps[s.timetable_entry.id].timetable_swap.is_cancelled) ? j(x).addClass('alloted').addClass('cancelled') : j(x).addClass('alloted');
                                        (this_timetable_swap !== undefined && this_timetable_swap.timetable_swap.is_cancelled) ? j(x).addClass('alloted').addClass('cancelled') : j(x).addClass('alloted');
                                    }
                                    else if(allocation_type == "weekly"){
                                        classroom_allocations.select(function(ca){
                                            if (ca.classroom_allocation.id == c.allocated_classroom.classroom_allocation_id && ca.classroom_allocation.allocation_type == "weekly"){
                                                j(x).addClass('alloted');
                                            }
                                        });
                                    }
                                }
                            });


                        });
                    }
                }
            })
        });
    }
    if(j(box).find('.section').length == 0){
        j(box).append(drawNoTimetableMessage());
    }
    return box;
}

function shorten_string(string, length){
    if(string == undefined)
        return no_teacher;
    str_len = string.length;
    if(str_len > length){
        return ((length - 3) > 0 ? string.slice(0,(length-3))+'...' : string.slice(0,length)+'...');
    }else{
        return string;
    }
}

function drawEmptyBox(){
    var max_width = j('.box').width();
    j('.section').each(function(s){
        var width = j(this).children('.subjects').width();
        while(width<(max_width-35)){
            var x = "<div class='empty_box'></div>"; //j(j(this).children('.subjects').children('.sub')).first().cloneNode();
            width = width + j(j(this).children('.subjects').children('.sub')).first().width();
            j(this).children('.subjects').append(x);
        }
    })
}

function drawNoTimetableMessage(){
    var warning_box = j('<div>',{'class': 'no_periods'});
    var warning_message_box = j('<span>',{'text': no_timetable_warning_message});
    return j(warning_box).append(warning_message_box);
}

function renderRooms(){
    j.get('/classroom_allocations/render_classrooms', function(result) {
        j('.allocations').append(result);
    });
}


function makeDroppable(){
    j('.sub').droppable({
        drop: function (event, ui) {
            var jthis = j(this).attr('id');
            cname = j(this).attr('id');
            drag_element = ui.draggable.attr('id');
            if (!j(this).hasClass('cancelled')) {
                new Ajax.Request('/classroom_allocations/update_allocation_entries', {
                    parameters: {
                        classroom_id: j('#' + ui.draggable.attr('id')).attr("data"),
                        subject_id: j('#' + cname).data("info")["sub_id"],
                        emp_id: j('#' + cname).data("info")["emp_id"],
                        batch_id: j('#' + cname).data("info")["batch_id"],
                        alloc_type: allocation_type,
                        date: month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1),
                        timetable: selected_tt,
                        weekday: parseInt(j('.active_day').attr("id")),
                        classtiming: j('#' + cname).data("info")["class_timing_id"],
                        tte_id: j('#' + cname).data("info")["tte_id"]
                    },
                    asynchronous: true,
                    evalScripts: true,
                    method: 'get',
                    onComplete: function (resp) {
                        if(resp.responseJSON.msg.length == 0){
                            var room = [];
                            continueAllocation(resp.responseJSON, month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1), room);
                        }else{
                            showStatus(resp.responseJSON, month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1));
                        }
                    }
                });
            }else{
                j(drag_element).droppable('disable');
            }
        },
        hoverClass: "drop-hover"
    });
}

function searchBatches(){
    var searchField = j('#search').val();
    search_batches = {};
    batches = {};
    var myExp = new RegExp(searchField, 'i');
    if (searchField != ""){
        for (key in all_batches){
            if(all_batches[key].match(myExp)){
                search_batches[key] = all_batches[key];
            }
        }
        batches = search_batches;
        j('.alloc_box').html(drawBox());
    }
    else{
        batches = all_batches;
        j('.alloc_box').html(drawBox());
    }
}


function showStatus(respjson,date){
    var room=[];
    if (respjson.status == true){
        //        j('#' + cname).css("background-color","#ffe7e7");
        //        originalBg = j('#' + drag_element ).css("background-color","#ffe7e7");
        class_rooms.select(function(cr){
            if (cr.classroom.id == j('#' + drag_element ).attr('data')) room.push(cr.classroom.name);
        })
        if (j('#'+ cname + ' ' + '.subtooltip').children('#' + j('#' + drag_element ).attr("data")).length == 0){
            room.each(function(c){
                j('#'+ cname + ' ' + '.subtooltip').append("<div class='room_name'" + "id=" + j('#' + drag_element ).attr("data") + ">" + "<span id='rname'" + c + "</span" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>")
            })
        }
    }

    if (respjson.status == false) {
        j('.sub').droppable('option', 'disabled', true);
        j('.alloc_box').addClass("transparency");
        var warning = document.createElement('div').addClassName("warning");
        j('.allocations').append(warning);
        var warning_msg = document.createElement('div').addClassName("warning_msg");
        var msg = "";
        respjson.msg.each(function(m){
            msg = msg +"<li>" + m + "</li>";
        })
        j(warning_msg).append(msg);
        j('.warning').append(warning_msg);
        var buttons = document.createElement('div').addClassName("confirm_buttons");
        j(warning).append(buttons);
//        j(j('.warning_msg li').last()).css("list-style","none")
//        j(j('.warning_msg li').last()).css("font-weight","normal")
        j('.warning_msg li').css("list-style","none").css("font-weight","normal")
        var continue_btn = "<button type='button' class ='continue_btn'>" + continue_text + "</button>"
        var cancel_btn = "<button type='button' class ='cancel_btn'>" + cancel_text + "</button>"
        j(buttons).append(continue_btn);
        j(buttons).append(cancel_btn);
        j('.continue_btn').click(function(){
            continueAllocation(respjson, date, room);
        });
//        j('.continue_btn').click(function(){
//            j('.warning').hide();
//            j('.alloc_box').removeClass("transparency");
//            j('#' + cname).addClass('alloted');//css("background-color","#ffe7e7");
//            j.get('/classroom_allocations/override_allocations',{
//                date: date,
//                alloc_type: allocation_type,
//                status: respjson.status,
//                classroom: respjson.classroom,
//                timetable_entry: respjson.timetable_entry,
//                allocation: respjson.allocation,
//                subject: respjson.subject
//            })
//            class_rooms.select(function(cr){
//                if (cr.classroom.id == j('#' + drag_element ).attr('data')) room.push(cr.classroom.name);
//            })
//            if (j('#'+ cname + ' ' + '.subtooltip').children('#' + j('#' + drag_element ).attr("data")).length == 0){
//                room.each(function(c){
//                    j('#'+ cname + ' ' + '.subtooltip').append("<div class='room_name'" + "id=" + j('#' + drag_element ).attr("data") + ">" + "<span id='rname'>" + c + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>")
//                })
//            }
//        });
        j('.cancel_btn').click(function(){
            j('.warning').hide();
            j('.alloc_box').removeClass("transparency");
        });
        j('.sub').droppable('option', 'disabled', false);
        if (respjson.flag == false) {
            j('.continue_btn').hide();
            j('.cancel_btn').css({
                "background-color":"#00628f",
                "color":"white"
            });
        }
    }
}

function continueAllocation(respjson, date, room){
//    j('.continue_btn').click(function(){
            j('.warning').hide();
            j('.alloc_box').removeClass("transparency");
            j('#' + cname).addClass('alloted');//css("background-color","#ffe7e7");
            j.get('/classroom_allocations/override_allocations',{
                date: date,
                alloc_type: allocation_type,
                status: respjson.status,
                classroom: respjson.classroom,
                timetable_entry: respjson.timetable_entry,
                allocation: respjson.allocation,
                subject: respjson.subject
            })
            class_rooms.select(function(cr){
                if (cr.classroom.id == j('#' + drag_element ).attr('data')) room.push(cr.classroom.name);
            })
            if (j('#'+ cname + ' ' + '.subtooltip').children('#' + j('#' + drag_element ).attr("data")).length == 0){
                room.each(function(c){
                    j('#'+ cname + ' ' + '.subtooltip').append("<div class='room_name'" + "id=" + j('#' + drag_element ).attr("data") + ">" + "<span id='rname'>" + c + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>")
                })
            }
//        });
}

function removeRoom(ele){
    parent = j(ele).parents('.sub');
    val = j(ele).parents('.sub').data();
    j('.sub').droppable('option', 'disabled', true);
    j('.alloc_box').addClass("transparency");
    var warning = document.createElement('div').addClassName("warning");
    j('.allocations').append(warning);
    var warning_msg = document.createElement('div').addClassName("warning_msg");
    j(warning_msg).text(delete_allocation);
    j(warning).append(warning_msg);
    var buttons = document.createElement('div').addClassName("confirm_buttons");
    j(warning).append(buttons);
    var continue_btn = "<button type='button' class ='continue_btn'>" + continue_text + "</button>"
    var cancel_btn = "<button type='button' class ='cancel_btn'>" + cancel_text + "</button>"
    j(buttons).append(continue_btn);
    j(buttons).append(cancel_btn);

    j('.continue_btn').click(function(){
        j('.warning').hide();
        j('.alloc_box').removeClass("transparency");
        var r_id = j(ele).parents('.room_name').attr("id");
        j.get('/classroom_allocations/delete_allocation',{
            tte_id: val.info.tte_id ,
            batch_id: val.info.batch_id,
            emp_id: val.info.emp_id,
            sub_id: val.info.sub_id,
            weekday_id: val.info.weekdayid,
            class_timing_id: val.info.class_timing_id,
            alloc_type: allocation_type,
            date: month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1),
            tt_id: selected_tt,
            room_id: r_id
        });

        j('.sub').droppable('option', 'disabled', false);
        j(j(ele).parents('.room_name')).remove();

        if(j(parent).children().children('.room_name').length == 0){
            j(parent).removeClass('alloted');
        }

        ele.remove();



    });

    j('.cancel_btn').click(function(){
        j('.warning').hide();
        j('.alloc_box').removeClass("transparency");
        j('.sub').droppable('option', 'disabled', false);
    });
}
