// TODO move to separate file
/*
 * Natural Sort algorithm for Javascript - Version 0.6 - Released under MIT license
 * Author: Jim Palmer (based on chunking idea from Dave Koelle)
 * Contributors: Mike Grier (mgrier.com), Clint Priest, Kyle Adams, guillermo
 */
function naturalSort(a, b) {
    var re = /(^-?[0-9]+(\.?[0-9]*)[df]?e?[0-9]?$|^0x[0-9a-f]+$|[0-9]+)/gi,
            sre = /(^[ ]*|[ ]*$)/g,
            dre = /(^([\w ]+,?[\w ]+)?[\w ]+,?[\w ]+\d+:\d+(:\d+)?[\w ]?|^\d{1,4}[\/\-]\d{1,4}[\/\-]\d{1,4}|^\w+, \w+ \d+, \d{4})/,
            hre = /^0x[0-9a-f]+$/i,
            ore = /^0/,
            // convert all to strings and trim()
            x = a.toString().replace(sre, '') || '',
            y = b.toString().replace(sre, '') || '',
            // chunk/tokenize
            xN = x.replace(re, '\0$1\0').replace(/\0$/, '').replace(/^\0/, '').split('\0'),
            yN = y.replace(re, '\0$1\0').replace(/\0$/, '').replace(/^\0/, '').split('\0'),
            // numeric, hex or date detection
            xD = parseInt(x.match(hre)) || (xN.length != 1 && x.match(dre) && Date.parse(x)),
            yD = parseInt(y.match(hre)) || xD && y.match(dre) && Date.parse(y) || null;
    // first try and sort Hex codes or Dates
    if (yD)
        if (xD < yD)
            return -1;
        else if (xD > yD)
            return 1;
    // natural sorting through split numeric strings and default strings
    for (var cLoc = 0, numS = Math.max(xN.length, yN.length); cLoc < numS; cLoc++) {
        // find floats not starting with '0', string or 0 if not defined (Clint Priest)
        oFxNcL = !(xN[cLoc] || '').match(ore) && parseFloat(xN[cLoc]) || xN[cLoc] || 0;
        oFyNcL = !(yN[cLoc] || '').match(ore) && parseFloat(yN[cLoc]) || yN[cLoc] || 0;
        // handle numeric vs string comparison - number < string - (Kyle Adams)
        if (isNaN(oFxNcL) !== isNaN(oFyNcL))
            return (isNaN(oFxNcL)) ? 1 : -1;
        // rely on string comparison if different types - i.e. '02' < 2 != '02' < '2'
        else if (typeof oFxNcL !== typeof oFyNcL) {
            oFxNcL += '';
            oFyNcL += '';
        }
        if (oFxNcL < oFyNcL)
            return -1;
        if (oFxNcL > oFyNcL)
            return 1;
    }
    return 0;
}

var employees,json_data,today,dept,translated;
function drawRegister(dpt_id,date){
    params = 'dept_id='+dpt_id
    if (date!=undefined){
        params = params + '&next='+date;
    }
    j("#loader").show();
    if (dpt_id == ""){
        j("#register").children().remove();
        j("#loader").hide();
    }else{
        new Ajax.Request('/employee_attendances/show.json',{
            parameters: params,
            asynchronous:true,
            evalScripts:true,
            method:'get',
            onComplete:function(resp){
                registerBuilder(resp.responseJSON);
                j("#loader").hide();
            }
        });
    }
}

function registerBuilder(data){
    json_data = data;
    today = data.today;
    dept = data.dept.employee_department;
    translated = data.translated;
    employees = data.employees;    
    absence = data.absence;
    date_headers = data.date_headers;
    absence = data.absence;
    current_day = data.current_day;
    current_date = data.current_date;
    selected_date = data.selected_date;
    
    //sort list
    if ($("sort_selector") != null) {
        sort_employees_array(get_sort_order());
    }
    
    var register = j("#register");

    var header = j('<div/>', {
        'class': 'header'
    });

    j(register).html(header);

    var prev = j('<div/>', {
        'class': 'prev'
    }).appendTo(header)

    var prev_link = j("<a>", {
        text: "◄",
        href: "",
        'onclick': "loadMonth('prev'); return false;"
    }).appendTo(prev);

    var month = j('<div/>', {
        'class': 'month',
        text: today
    }).appendTo(header)

    var next = j('<div/>', {
        'class': 'next'
    }).appendTo(header)

    var next_link = j("<a>", {
        text: "►",
        href: "",
        'onclick': "loadMonth('next'); return false;"
    }).appendTo(next);

    var extender = j("<div/>",{
        'class': 'extender'
    }).appendTo(header);

    drawBox();
    if ($("sort_selector") == null) {
        var sort_selector = drawSortSelector();
        $('register').insert({before: sort_selector});
    }
}


function loadMonth(month){
    if(month == 'prev'){
        m = (new Date(json_data.month_year )).getMonth() ;
    }else if(month == 'next'){
        m = parseInt((new Date(json_data.month_year )).getMonth()) + 2;
    }
    if(m == 0){
        m = 12;
        y = (new Date(json_data.month_year)).getFullYear() - 1;
    }
    if(m == 13){
        m = 1;
        y = (new Date(json_data.month_year)).getFullYear() + 1;
    }
    d = (new Date(json_data.month_year)).getDate();
    date = y.toString() + "-"+m.toString() +"-"+ d.toString();
    j("#loader").show();
    drawRegister(dept.id,date);
}

function drawBox(){
    
    
    var register = j("#register");

    var header = j('<div/>', {
        'class': 'box-1'
    }).appendTo(register);

    var table = j('<table/>', {
        id: 'register-table'
    }).appendTo(header);

    var tr_head = j('<tr/>', {
        'class': 'tr-head'
    }).appendTo(table);

    var td_header_name = j('<td/>', {
        'class': 'head-td-name themed_text',
        text: 'Name'
    }).appendTo(tr_head);

    j.each(date_headers,function(i,v){
        var td = j('<td/>', {
            'class': 'head-td-date'
        }).appendTo(tr_head);

        var day = j('<div/>', {
            'class': 'day themed_text',
            text: v.day
        }).appendTo(td);

        var date = j('<div/>', {
            'class': 'date',
            text: v.date
        }).appendTo(td);
        
    })

    j.each(employees,function(i,v){
        var emp_tr = j('<tr/>', {
            'class': 'tr-odd'
        }).appendTo(table);

        var emp_td = j('<td/>', {
            'class': 'td-name'
        }).appendTo(emp_tr);

        j(emp_td).html(v.employee.first_name + " " + v.employee.middle_name + " " + v.employee.last_name + " "+'<span>(' +v.employee.employee_number +')</span>&lrm;');
        var emp_name = j('<td/>', {
            'class': 'date'
        }).appendTo(emp_td);

        var span = j('<span/>', {}).appendTo(emp_name);

        var emp_name_text = j('<td/>', {
            'class': 'themed_text',
            text: v.employee.first_name + (v.employee.middle_name || "") + (v.employee.last_name || "")
        }).appendTo(span);

        j.each(date_headers,function(i,val){
            m = ("0" + String((new Date(json_data.month_year)).getMonth() + 1) ).slice(-2);
            y = (new Date(json_data.month_year)).getFullYear();
            
            var emp_day_td = j('<td/>', {
                id: "attendance-employee-" + String(v.employee.id) + "-day-" + y.toString()+"-"+m.toString()+"-" + String(val.date),
                'class': 'td-mark'
            }).appendTo(emp_tr);
            
            if (current_date == selected_date && val.date == current_day){
                j(emp_day_td).addClass("active");
            }
            
            attendance = absence[v.employee.id];
            emp_id = v.employee.id;
           
            date = y.toString() + "-"+m.toString() +"-"+ val.date.toString();

            if(attendance!= undefined){
                employee_dates = attendance.map(function(e){
                    return e.date
                });
                j.each(attendance,function(i,att){
                    if(att.date ==  date){
                        att_id = att.att_id;
                        return false;
                    }else{
                        att_id = undefined;
                    }
                })
                if (att_id != undefined && employee_dates.indexOf(date) > -1 ){
                    var mark_att = j("<a>", {
                        text: "X",
                        href: "",
                        'data' : {
                            id: emp_id,
                            date: date,
                            att_id: att_id
                        },
                        'class': "absent themed_text",
                        'onclick': "edit_attendance(j(this)); return false;"
                    }).appendTo(emp_day_td);
                }
                else{

                    var no_att = j("<a>", {
                        href: "",
                        'class': 'present',
                        'data' : {
                            id: emp_id,
                            date: date
                        },
                        'onclick': "new_attendance(j(this)); return false;"
                    }).appendTo(emp_day_td);
                }
               
            }
            else{
                var no_att = j("<a>", {
                    href: "",
                    'class': 'present',
                    'data' : {
                        id: emp_id,
                        date: date
                    },
                    'onclick': "new_attendance(j(this)); return false;"
                }).appendTo(emp_day_td);
            }

            var emp_date_cell = j("<div/>", {
                'class':"date"
            }).appendTo(emp_day_td);

            var emp_span = j("<span/>", {
                'class':"themed_text",
                text: val.day + " "+val.date
            }).appendTo(emp_date_cell);

            j(emp_span).append("<div>" + v.employee.first_name + v.employee.middle_name + v.employee.last_name + "</div>")

        })

        
   
    })
    
    j(register).append(header);
}




function new_attendance(ele){
    emp_id = j(ele).data("id");
    date = j(ele).data("date");
    params = 'id='+date+'&id2='+emp_id+'&date='+date
    new Ajax.Request('/employee_attendances/new',{
        parameters: params,
        asynchronous:true,
        evalScripts:true,
        method:'get',
        onComplete:function(resp){
        //            registerBuilder(resp.responseJSON);
        //            j("#loader").hide();
        }
    });
}

function edit_attendance(ele){
    id = j(ele).data("att_id");
    date = j(ele).data("date");
    new Ajax.Request('/employee_attendances/edit/'+id,{
        parameters: 'date='+date,
        asynchronous:true,
        evalScripts:true,
        method:'get',
        onComplete:function(resp){
        //            registerBuilder(resp.responseJSON);
        //            j("#loader").hide();
        }
    });
//{:url => edit_employee_attendance_path(@absent[0]), :method => 'get'}, :class=> 'absent themed_text') %>
}

function drawSortSelector(){
      var newdiv = new Element('div', {
          'class': 'sort_selector',
          'id': 'sort_selector'
      });
      var form = new Element('form', {'id': 'sort_form'});
      var form_label = new Element('label', {'id': 'form_label'}).update(translated.sort_by);
      var sort_by_name_input = new Element('input', {'id': 'sort_by_name', 'value': 0, 'name': 'sort_order_selector', 'type': 'radio', 'checked': 'checked', 'class': 'sort_by_input'});
      var sort_by_employee_number_input = new Element('input', {'id': 'sort_by_employee_number', 'value': 1, 'name': 'sort_order_selector', 'type': 'radio', 'class': 'sort_by_input'});
      var sort_by_name_label = new Element('label', {'for': 'sort_by_name', 'class': 'sort_by_label', 'id': 'sort_by_name_label'}).update(translated.name);
      var sort_by_employee_number_label = new Element('label', {'for': 'sort_by_employee_number', 'class': 'sort_by_label', 'id': 'sort_by_employee_number_label'}).update(translated.employee_number);
      form.appendChild(form_label);
      form.appendChild(sort_by_name_input);
      form.appendChild(sort_by_name_label);
      form.appendChild(sort_by_employee_number_input);
      form.appendChild(sort_by_employee_number_label);
      form.observe('change', sort_employees);
      newdiv.appendChild(form);
      return newdiv;
}

function update_json(val) {
    // date_today = $('time_zone').value;
    Element.show('loader');
    if (val) {
        new Ajax.Request('/employee_attendances/show.json', {
            parameters: 'dept_id=' + val + '&next=' + formatDate(json_data.month_year),
            asynchronous: true,
            evalScripts: true,
            method: 'get',
            onComplete: function (resp) {
                update_json_values(resp.responseJSON);
                sort_employees_array(get_sort_order());
                update_employees_list();
                Element.hide('loader');
            }
        });
    } else
    {
        j("#register").children().hide();
        Element.hide('loader');
    }
}

function update_json_values(respjson) {
    json_data = respjson
    employees = respjson.employees;
    absence = respjson.absence;
    date_headers = respjson.date_headers;
    absence = respjson.absence;
    current_day = respjson.current_day;
    current_date = respjson.current_date;
    selected_date = respjson.selected_date;
}

function sort_employees(event) {
    sort_order = get_sort_order();
    update_json($("batch_id").value);
}
function get_sort_order() {
    value = $$('input:checked[type=radio][name=sort_order_selector]')[0].value;
    return parseInt(value);
}
function sort_employees_array(order) {
    // 0 -> by_first_name
    // 1 -> by emplopyee id
    
    if (order == 0) {

        employees = employees.sortBy(function (s) {
            return s.employee.first_name;
        });
    } else if (order == 1) {
        employees = employees.sort(function (a, b) {
            return naturalSort(a.employee.employee_number, b.employee.employee_number);
        });

    }
}
function update_employees_list(){
    Element.remove($$(".box-1")[0]);
    box = drawBox();
}

function formatDate(date) {
    var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;

    return [year, month, day].join('-');
}
