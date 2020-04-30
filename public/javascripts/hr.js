rowsPerPage = 10,currentR = 1,newCategoryCount = 0, savedState = [],currentPage = 1,savedArr = [],cost_of_company = 0;
// main function
function drawTable(json_data){
    response = json_data;
    console.log(response);
    sortData();
    sDate = response.theader.start_date
    eDate = response.theader.end_date
    date_range = response.theader.date_range
    pgId = response.theader.pg_id
    pgName = response.theader.pg_name
    currentData = JSON.parse(JSON.stringify(response));
    originalData = JSON.parse(JSON.stringify(response));
    intermediateData = JSON.parse(JSON.stringify(response));
    dir_flag = (document.getElementsByTagName('html')[0].getAttribute('dir') == 'ltr');
    setCounts();
    if(totEmpCount == 0){
        url = window.location.origin +"/employee_payslips/generate_payslips/" + String(pgId) + "?end_date=" + String(eDate) + "&start_date=" + String(sDate)
        window.location.replace(url)
    }
    calculateAllPageContent();
    paginateTable();
    updatePaginationStatus(1);
    drawTableHeader();
    drawTableBody(pageContent1);
    j("#total_cost b").text(cost_of_company.toFixed(precision) +" " +response.theader.currency);
    removeOverlay();
}

// Full overlay
showOverlay = function(){
    document.getElementById("overlay").className = "OverlayEffect";
    document.getElementById("overlay").style.height = "400px";
    j("#overlay").append('<span id= "loading_text">Loading...</span>')
    j("#contents").hide();
    j("#overlay").show();
}

removeOverlay = function(){
    document.getElementById("overlay").className = "";
    j("#overlay").html("");
    j("#overlay").hide();
    j("#contents").show();
}

// Overlay for table
withOverlay = function(fn){
    showOverlay();
    setTimeout(function(){
        fn.call();
        removeOverlay();
    },50)
}


// Sort the employees
sortData = function(){
    var arr = [];
    j.each(response.tbody, function(i,v){
        if (v != null && v!= undefined){
            if(v['emp_id'])
                v['emp_id'] = v['emp_id'];
            else
                v['emp_id'] = i;
            arr.push(v)
        }
    })
    arr.sort(function(a,b){
        return (b.checked - a.checked)
    });

    arr.sort(function(a, b){
        if(a.name < b.name) return -1;
        if(a.name > b.name) return 1;
        return 0;
    })
    response.tbody = arr
}


//Set the earnings, deduction, total employee count

setCounts = function(){
    totNoEarnings = Object.keys(currentData.theader.earnings).length +  Object.keys(currentData.theader.individual_earnings).length ;
    totNoDeductions = Object.keys(currentData.theader.deductions).length + Object.keys(currentData.theader.individual_deductions).length ;
    totEmpCount = 0;
    JSON.parse(currentData.tbody).each(function(x){
        if (x.saved == 0 && savedArr.indexOf(x.emp_id) == -1) totEmpCount+=1
    });
}


// paginate table 
paginateTable = function(){
    if (totEmpCount > rowsPerPage){
        jQuery(".pagination").pagination({
            items: totEmpCount,
            itemsOnPage: rowsPerPage,
            cssStyle: 'light-theme',
            displayedPages: 8,
            prevText: "< Previous",
            nextText: "Next >",
            onPageClick: function(pageNumber, event){
                currentPage = pageNumber;
                content = eval("pageContent" + String(pageNumber));
                drawTableHeader();
                drawTableBody(content);
                j(".pagination").pagination('drawPage', pageNumber);
                updateSelectedStatus();
                updatePaginationStatus(pageNumber);
            }
        });
        j(".pagination").append("<div class='pagination_status'>" + t.selected+ "1 - " + String(rowsPerPage) + t.of + String(totEmpCount) + "</div>")
        j(".pagination").show();

    }
    else
    {
        j(".pagination").hide();
    }
}


// update the employee status below the table
updatePaginationStatus = function(page){

    var start_range = ( page - 1 )* rowsPerPage + 1
    var end_range = (start_range - 1 ) + rowsPerPage
    if (totNumber != page)
        j(".pagination_status").html( t.showing +" "+ String(start_range) + " - " + String(end_range) + t.of + String(totEmpCount) )
    else
        j(".pagination_status").html( t.showing +" " +String(start_range) + " - " + String(totEmpCount) + t.of + String(totEmpCount))
    j(".pagination_status").show();
}

// Calculate all page contents

calculateAllPageContent = function(){
    var employees = JSON.parse(currentData.tbody).map(function(x){
        if(x.saved == 0 && savedArr.indexOf(x.emp_id) == -1)
            return x['emp_id']
    })

    page_number = 0;
    employees = employees.filter(Boolean);
    employees = j.unique(employees);
    for (i=0,c=totEmpCount; i<c; i+=rowsPerPage) {
        page_number = page_number + 1;
        eval("page" + String(page_number) + "=" + "'" + String(employees.slice(i,i+rowsPerPage)) + "'" );
        eval("pageContent" + String(page_number) + "= []"   )
        arr = employees.slice(i,i+rowsPerPage)
        j.each(arr, function(i,v){
            var page =  eval("pageContent" + String(page_number))
            emp_record = JSON.parse(currentData.tbody).select(function(x){
               
                if (x['emp_id'] == v){
                    return x
                }
            })
            page.push(emp_record[0])
        })
    }
    totNumber = page_number;
}


// draw table header

drawTableHeader = function(){
    setCounts();
    var tbl = document.createElement('table')
    j("#payslip_table").html(tbl);
    var firstHeaderRow = document.createElement('tr')

    j('<td/>', {
        colspan: 2
    }).appendTo(firstHeaderRow);


    var spanEarningCol = j('<td/>', {
        colspan: totNoEarnings + 1,
        'class': 'earning header-col'
    })


    var spanEarningHeading = j('<div/>', {
        'class': 'cat_header',
        text: t.earnings
    }).appendTo(spanEarningCol)

    var addEarningLink = j('<div/>', {
        'class': 'add_link themed_text',
        'id':'earning',
        'onclick': 'showModalBox();',
        text: t.add
    }).appendTo(spanEarningCol);

    j(firstHeaderRow).append(spanEarningCol);

    var spanDeductionCol = j('<td/>', {
        colspan: totNoDeductions + 1,
        'class': 'deduction header-col'
    })


    var spanDeductionHeading = j('<div/>', {
        'class': 'cat_header',
        text: t.deductions
    }).appendTo(spanDeductionCol);


    var addDeductionLink = j('<div/>', {
        'class': 'add_link themed_text',
        'id':'deduction',
        'onclick': 'showModalBox();',
        text: t.add
    }).appendTo(spanDeductionCol)


    j(firstHeaderRow).append(spanDeductionCol);
    j(tbl).append(firstHeaderRow);

    // Second header

    var secondHeaderRow =  j('<tr/>', {
        'class': "tr-head"
    });

    var selectAllCol = document.createElement('th')
    j(selectAllCol).addClass("chkbox");

    var selectAllCheckBox = j('<input/>', {
        'class': 'check_box',
        'id': 'select_all',
        'type': 'checkbox'
    }).appendTo(selectAllCol);

    j(secondHeaderRow).append(selectAllCol);


    var empNameHeader = j('<th/>', {
        'class': "emp_name_header",
        'text': t.employee_name
    }).appendTo(secondHeaderRow);


    var empDptHeader =  j('<td/>', {
        'class': "dpt_name",
        'text': t.department
    }).appendTo(secondHeaderRow);

    j.each( JSON.parse(currentData.theader.earnings_order), function(i, id){
        cat_name = currentData.theader.earnings[id];
        drawCategory(secondHeaderRow,cat_name);
    });

    j.each( currentData.theader.individual_earnings, function(id,name){
        drawIndividualCategory(secondHeaderRow,name,"individual_earnings-"+id);
    });

    var totEarningHeader = j('<td/>', {
        'class': "tot_earning_header",
        'text': t.total_earning
    }).appendTo(secondHeaderRow);

    j.each( JSON.parse(currentData.theader.deductions_order), function(i, id){
        cat_name = currentData.theader.deductions[id];
        drawCategory(secondHeaderRow,cat_name);
    });

    j.each( currentData.theader.individual_deductions, function(id,name){
        drawIndividualCategory(secondHeaderRow,name,"individual_deductions-"+id);
    });

    var totDeductionHeader = j('<td/>', {
        'class': "tot_deduction_header",
        'text': t.total_deduction
    }).appendTo(secondHeaderRow);

    var netPayHeader =  j('<td/>', {
        'class': "net_pay_header",
        'text': t.net_pay
    }).appendTo(secondHeaderRow);

    var resetAll = j('<td/>', {
        'class': "reset_link themed_text",
        'text': t.reset_all,
        onclick: "resetEntireTable();"
    }).appendTo(secondHeaderRow);

    j(tbl).append(secondHeaderRow)

}

// draw the earnings & deductions

drawCategory =function(row, name){
    var cat_header = j('<td/>', {
        'class': "category_name"
    }).appendTo(row);
    j(cat_header).html("<div>"+name+"</div>");

}

// draw the individual earnings & deductions

drawIndividualCategory = function(row,name,id){
    var cat_header = j('<tr/>', {
        id: id,
        "class": "individual_category"
    })
    var cat_header_content = j('<td/>', {
        'class': "cat_header_content"
    });

    var cat_name = j('<div/>', {
        'class': "cat_name",
        text: name
    }).appendTo(cat_header_content);

    var close_button = j('<div/>', {
        'class': "close"
    }).appendTo(cat_header_content);

    j(close_button).click(function(){
        removeIndividualCategoryConfirmation(id);
    })
    j(row).append(cat_header_content);

}

function to_round_off(net_pay){
    var arr = [1,2,6,7]
    var rounding_for = j("#rounding_for").data('attrs');
    if (rounding_for == 2){
      var value = net_pay - parseInt(net_pay)
      if(value >= 0.5){
        net_pay = parseInt(net_pay) + 1;
      }
      else {
        net_pay = parseInt(net_pay);
      }
      console.log(net_pay);
    }
    else if(rounding_for == 3){
      if (arr.includes(parseInt(net_pay) % 5)){
        net_pay = (parseInt(net_pay) - (parseInt(net_pay) % 5))
      }
      else if ((parseInt(net_pay) % 5) == 0)
        net_pay = parseInt(net_pay);
      else{
        net_pay = (parseInt(net_pay) +( 5 - (parseInt(net_pay) % 5 )));
      }
    }
    else if(rounding_for == 4){
      if ((parseInt(net_pay) % 10) >= 5){
        net_pay = (parseInt(net_pay) +( 10 - (parseInt(net_pay) % 10 )));
      }
      else {
        net_pay = (parseInt(net_pay) - (parseInt(net_pay) % 10));
      }
    }
    else{
      net_pay = Math.ceil(net_pay);
    }
    return net_pay;
  }
 
// draw table body
drawTableBody = function(contents){
    j(".data_row").remove();

    j.each(contents.filter(Boolean),function(i,e){
        if(e.saved == 1){
            return false;
        }
        var employee_id = e.emp_id;

        var empPayslipRow = j('<tr/>', {
            id: employee_id,
            'class': "data_row tr-even"
        })

        var empCheckBox = j('<th/>', {
            'class': 'check_box'
        })

        var status = (e.status == true) && (e.checked == 1)
        var chkBox = j('<input/>', {
            'type': 'checkbox',
            'id': employee_id,
            'checked': status
        }).appendTo(empCheckBox);

        if (e.status == false) {
            j(chkBox).attr({
                'disabled': true
            })
        }

        j(empPayslipRow).append(empCheckBox);


        var empName =  j('<th/>', {
            'class': "emp_name"
        }).appendTo(empPayslipRow);

        j(empName).html("<div class='e_name'>" +e.name+"</div>")
        j(empName).children(".e_name").attr("tooltip", e.name)
        
        var dptName = j('<td/>', {
            'class': "dpt_name"
        }).appendTo(empPayslipRow);

        j(dptName).html(e.department);

        var earningTot = 0;

        // looping earnings
        j.each( JSON.parse(currentData.theader.earnings_order), function(i, key){
            val = e.earnings[key]
            earningTot += parseFloat(val[1]);
            var catName = j('<td/>', {
                id: employee_id+"-"+"earnings"+"-"+key,
                'class': "cat_amount precision_text"
            }).appendTo(empPayslipRow);

            if (isNaN(parseFloat(val[1]).toFixed(precision)))
                val = "-"
            else
                val = parseFloat(val[1]).toFixed(precision)

            if (e.status){
                j(catName).append("<span onclick='makeTdEditable(this)'>" + val + "</span>")
            }
            else{
                j(catName).append(val);
            }
        });

        j.each(e.individual_earnings,function(key,v){
            if(val[1] != "-" ){
                earningTot += parseFloat(v[1]);
            }

            var catName = j('<td/>', {
                id: employee_id+"-"+"individual_earnings"+"-"+key,
                'class': "cat_amount precision_text"
            }).appendTo(empPayslipRow);

            if (isNaN(parseFloat(v[1]).toFixed(precision)))
                v = "-"
            else
                v = parseFloat(v[1]).toFixed(precision)
           
            if (e.status){
                j(catName).append("<span onclick='makeTdEditable(this)'>" + v + "</span>")
            }
            else{
                j(catName).append(v);
            }
        })

        var earningSum = j('<td/>', {
            'class': "tot_earning",
            'text': earningTot.toFixed(precision)
        }).appendTo(empPayslipRow);

        var deductionTot = 0;

        j.each( JSON.parse(currentData.theader.deductions_order), function(i, key){
            val = e.deductions[key];
            if(val[1] != "-" ){
                deductionTot += parseFloat(val[1]);
            }
            var catName = j('<td/>', {
                id: employee_id+"-"+"deductions"+"-"+key,
                'class': "cat_amount precision_text"
            }).appendTo(empPayslipRow);

            if (isNaN(parseFloat(val[1]).toFixed(precision)))
                val = "-"
            else
                val = parseFloat(val[1]).toFixed(precision)

            if (e.status){
                j(catName).append("<span onclick='makeTdEditable(this)'>" + val + "</span>")
            }
            else{
                j(catName).append(val);
            }
        });



        j.each(e.individual_deductions,function(key,val){

            deductionTot += parseFloat(val[1]);
            var catName = j('<td/>', {
                id: employee_id+"-"+"individual_deductions"+"-"+key,
                'class': "cat_amount precision_text"
            }).appendTo(empPayslipRow);

            if (isNaN(parseFloat(val[1]).toFixed(precision)))
                val = "-"
            else
                val = parseFloat(val[1]).toFixed(precision)

            
            if (e.status){
                j(catName).append("<span onclick='makeTdEditable(this)'>" + val + "</span>")
            }
            else{
                j(catName).append(val);
            }
        })

        var deductionSum = j('<td/>', {
            'text': deductionTot.toFixed(precision),
            'class': "tot_deduction"
        }).appendTo(empPayslipRow);

        var netSum =  earningTot - deductionTot
        var round_up_to = j("#round_off_value").data('attrs');
        if (round_up_to != 0)
        {
            netSum = to_round_off(netSum)
        }
        cost_of_company +=  netSum;
        var netPaySum = j('<td/>', {
            'text': netSum.toFixed(precision),
            'class': "net_pay"
        }).appendTo(empPayslipRow);
        e.net_pay = netSum;
        if (netSum < 0){
            markErrorRow(employee_id, t.net_pay_cannot_be_negative);
        }else{
            removeErrorRow(employee_id)
        }
        if (e.status == false) {
            reset_text = t.generated;
            j(empPayslipRow).addClass("disabled_row");
        }
        else{
            reset_text = ""
        }

        var empReset = j('<td/>', {
            'text': reset_text,
            'class': "emp_reset"
        }).appendTo(empPayslipRow);

        if (e.reset_status == true ){
            j(empReset).html("<a onclick='resetEmployeeRowConfirmation(this)'>Reset</a>")
        }

        j(empReset).addClass("emp_reset");
        j(empPayslipRow).append(empReset);
        j("table").append(empPayslipRow);

        if(e.error == 1){
            if (e.error_msg == undefined)
                markErrorRow(employee_id, t.net_pay_cannot_be_negative);
            else
                markErrorRow(employee_id, e.error_msg);
        }

        attachMiscEvents();
    })
    

}
// show modal box for individual category creation

showModalBox = function(){
    j("#category_name").val("");
    j("#amount").val("");
    document.getElementById("overlay").style.height = document.body.clientHeight + 'px';
    document.getElementById("overlay").style.display = 'block'
    document.getElementById("overlay").className = "FullOverlayEffect";
    document.getElementById("modalMsg").className = "ShowModal";
    if(dir_flag)
        j('#modalMsg').css({
            left : (j('body').width() - j('#modalMsg').width())/2
        });
    else
        j('#modalMsg').css({
            right : (j('body').width() - j('#modalMsg').width())/2
        });
}

// hide modal box after individual category creation

removeModalBox = function(){
    document.getElementById("modalMsg").className = "HideModal";
    document.getElementById("overlay").className = "";
    document.getElementById("overlay").style.height = '0px';
    j("#overlay").html("")
    return false;
}

// validate the individual category


validateIndividualCategory = function(name, amount){

    if(name && amount){
        createIndividualCategory(name, amount);
    }
    else
    {
        error_msg = t.cannot_be_blank;
        var category_input = j(".text-input-bg").has("#category_name").children(".errors");
        var amount_input = j(".text-input-bg").has("#amount").children(".errors")
        if (!name && amount) {
            category_input.html("<div class='error'>"+ error_msg +"</div>");
            amount_input.html("");
        }
        else if(name && !amount){
            var category_list = Object.values(currentData.theader.deductions).concat(Object.values(currentData.theader.earnings),Object.values(currentData.theader.individual_earnings),Object.values(currentData.theader.individual_deductions))
            if (category_list.indexOf(name) >= 0){
                category_input.html("<div class='error'>"+t.already_taken+"</div>")
            }
            j(category_input).html("");
            amount_input.html("<div class='error'>"+ error_msg  +"</div>");
        }
        else{
            category_input.html("<div class='error'>"+ error_msg +"</div>");
            amount_input.html("<div class='error'>"+ error_msg +"</div>");

        }
    }

}

//update the json with newly created individual category

createIndividualCategory = function(name, amount){
    is_deduction = j("#modalMsg").attr("is_deduction");
    cat_name = name;
    cat_amount = amount;
    var intermediate = JSON.parse(intermediateData.tbody);
    if(is_deduction == 1){
        newCategoryCount = newCategoryCount + 1;
        currentData.theader.individual_deductions[newCategoryCount] = name;
        intermediateData.theader.individual_deductions[newCategoryCount] = name;
        
        for (i=1; i<= page_number; i+=1) {

            eval("pageContent" + String(i)).each(function(x){

                if (x.status)
                {
                    x.individual_deductions[newCategoryCount] = [name, amount ];
                }
                else{
                    x.individual_deductions[newCategoryCount] = [name, "0" ];
                }
            })

        }

        intermediate.each(function(x){
            x.individual_deductions[newCategoryCount] = [name, "0" ];
        })

        intermediateData.tbody = JSON.parse(JSON.stringify(intermediate));


    }
    else
    {

        newCategoryCount = newCategoryCount + 1;
        currentData.theader.individual_earnings[newCategoryCount] = name;
        intermediateData.theader.individual_deductions[newCategoryCount] = name;
        
        for (i=1; i<= page_number; i+=1) {
            eval("pageContent" + String(i)).each(function(x){
                if (x.status)
                {
                    x.individual_earnings[newCategoryCount] = [name, amount ];
                }
                else{
                    x.individual_earnings[newCategoryCount] = [name, "0" ];
                }
            })
        }


        intermediate.each(function(x){
            x.individual_earnings[newCategoryCount] = [name, "0" ];
        })

        intermediateData.tbody = JSON.parse(JSON.stringify(intermediate));
      
    }
    drawTableHeader();
    
    recalculateNetPay();
    
    content = eval("pageContent" + currentPage);
    
    drawTableBody(content);
    return removeModalBox();
}


// attach events like select all, clear all, editable cell etc

attachMiscEvents = function(){
    updateSelectedStatus(); // count of total employees selected
    // on employee checkbox toggle update data
    j(".data_row input[type='checkbox']").change(function(){
        var id = j(this).attr("id");

        if(this.checked){
            var checked_value = 1;
        }
        else{
            var checked_value = 0;
        }
        //var data = JSON.parse(currentData.tbody);
        eval("pageContent" + String(currentPage)).each(function(x){
            if (x.emp_id == id) x.checked = checked_value;
        })
        //currentData.tbody = JSON.parse(JSON.stringify(data));
        var data = JSON.parse(currentData.tbody);
        data.each(function(x){
            if (x.emp_id == id) x.checked = checked_value;
        })
        currentData.tbody = JSON.parse(JSON.stringify(data));
        updateSelectedStatus();
        total_chk = j(".data_row input[type='checkbox']").length;
        checked_chk = j(".data_row input[type='checkbox']:checked").length;
        if(total_chk == checked_chk)
            j('#select_all').prop("checked", true);
        else
            j('#select_all').prop("checked", false);
    })

    // on page wise select all toggle

    j('#select_all').click(function(event) {  //on click
        var chkBoxEle =  j(".data_row input[type='checkbox']:enabled");
        var emp_ids =    j(chkBoxEle).map(function() {
            return this.id;
        });

        if(this.checked) { // check select status
            j(chkBoxEle).prop("checked", true);
            var checked_value = 1;

        }else{
            j(chkBoxEle).prop("checked", false);
            var checked_value = 0;

        }
       
        eval("pageContent" + String(currentPage)).each(function(x){
            x.checked = checked_value;
        })

        var data = JSON.parse(currentData.tbody)
        j.each(emp_ids, function(k,v){
            data.each(function(x){
                if (x.emp_id == v)
                    x.checked = checked_value;
            })
        })
        currentData.tbody = JSON.parse(JSON.stringify(data));
        updateSelectedStatus();
    });

    // selecting all employees

    j("#select_all_employees").click(function(){
       
        for (i=1; i<=totNumber; i++){
            eval("pageContent" + String(i)).each(function(x){
                x.checked = 1;
            })
        }
        j(".data_row input[type='checkbox']:enabled").prop("checked",true)
        j("#select_all").prop("checked",true)
        updateSelectedStatus();
        j(".clear_all_status").show();
        j(".select_all_status").hide();
    })

    // clear all employees

    j("#clear_all_employees").click(function(){
        for (i=1; i<=totNumber; i++){
            eval("pageContent" + String(i)).each(function(x){
                x.checked = 0;
            })
        }
        j(".data_row input[type='checkbox']:enabled").prop("checked",false)
        j("#select_all").prop("checked",false)
        updateSelectedStatus();
        j(".select_all_status").show();
        j(".clear_all_status").hide();
    })


    if (j(".data_row input[type='checkbox']:checked").length == j(".data_row input[type='checkbox']:enabled").length ){
        j('#select_all').prop("checked", true)
    }

    j('input[checked="checked"]').parents('tr').children('td.cat_amount').hover(
        function() {
            j( this ).addClass( "td_hover" );
        },function() {
            j( this ).removeClass( "td_hover" );
        }
        );


    j.each(j("td.category_name  div:first-child"), function(i,v){
        if(j(v).width() >= 180)
        {
            var helper_div= j('<div/>', {
                'text': j(v).text(),
                'class': "helper_info"
            }).appendTo(v);
            j(helper_div).hide();
            j(v).hover(
                function() {
                    j( this ).children(".helper_info").show();
                },function() {
                    j( this ).children(".helper_info").hide();
                }
                );
        }
    })
   
    j("#earning").click(function(){
        j("#MB_caption").text(t.add_earning);
        j("#modalMsg").attr({
            is_deduction: 0
        })
        j('#MB_content #ok').text(t.add_earning);
        j("#category_name").text("");
        j("#amount").text("");
    })

    j("#deduction").click(function(){
        j("#MB_caption").text(t.add_deduction);
        j("#modalMsg").attr({
            is_deduction: 1
        })
        j('#MB_content #ok').text(t.add_deduction);
        j("#category_name").val("");
        j("#amount").val("");
    })

    j(document).click( function(e){
        var t = e.target.nodeName;
        if (t != "SPAN" && t != "INPUT" ){
            j.each(j("td.cat_amount").has("input"),function(td){
                if (j(e.target).parent().attr("id") !=  j(this).attr("id"))
                {
                    var e_id = j(this).parent('tr').attr("id");
                    j(this).parent('tr').removeClass("td_hover");
                    j(this).parent('tr').children("th").removeClass("td_hover")
                    var prev_val = j(this).attr("input_val");
                    var curr_val = j(this).children("input").val();
                    if (prev_val != curr_val){
                        j(this).parent('tr').children("td:last").html("<a onclick='resetEmployeeRowConfirmation(this)'>Reset</a>");
                        eval("pageContent" + String(currentPage)).each(function(x){
                            if( e_id == x.emp_id)
                                x.reset_status = true
                        })
                    }
                    if (curr_val){
                        var amount = curr_val;
                    }
                    else{
                        var amount = prev_val;
                    }
                    j(this).html("<span onclick='makeTdEditable(this)'>" + parseFloat(amount).toFixed(precision) + "</span>");
                }
            })

        }
        j("td.cat_amount input").focusout(function(){
            var id = j(this).parent().attr("id").split("-");
            var emp_id = id[0];
            var category_type = id[1];
            var cat_id = id[2];
            var amount = j(this).val();
            var tot_earning = 0;
            var tot_deduction = 0;
            eval("pageContent" + String(currentPage)).each(function(x){
                if (emp_id == x.emp_id){
                    x.reset_status = true;
                    eval("var value = x."+ category_type + "["+cat_id+"]");
                    eval("value[1]= " + amount);
                    j.each(x.earnings,function(key,val){
                        tot_earning += parseFloat(val[1]);
                    })
                    
                    j.each(x.deductions,function(key,val){
                        tot_deduction += parseFloat(val[1]);
                    })
                    
                    j.each(x.individual_earnings,function(key,val){
                        tot_earning += parseFloat(val[1]);
                    })
                    
                    j.each(x.individual_deductions,function(key,val){
                        tot_deduction += parseFloat(val[1]);
                    })

                    x.net_pay = tot_earning - tot_deduction;
                }
            })
            recalculateSalary(this);
        })
    });

    j(".info-icon").hover(
        function() {
            j( this ).children(".cost_info").show();
        },function() {
            j( this ).children(".cost_info").hide();
        })


}


// update the number of employees selected

updateSelectedStatus = function(){
    selectEmpCount = 0;
    for (i=1; i<=totNumber; i++){
        eval("pageContent" + String(i)).each(function(x){
            if(x.checked)
                selectEmpCount+=1;
        })
    }
    
   
    if(selectEmpCount > 0){
        j(".clear_all_status").show();
        j(".select_all_status").hide();
    }else{
        j(".clear_all_status").hide();
        j(".select_all_status").show();
    }

    if(totEmpCount > 1){

        j(".status").text( String(selectEmpCount) + t.of + String(totEmpCount) +" "+ t.employees_selected);

    }
    else{
        j(".status").text( String(selectEmpCount) + t.of + String(totEmpCount) +" "+ t.employee_selected);
    }
}


// if net pay is negative mark as error row

markErrorRow = function(emp_id,error_text){
    j("tr#" + emp_id + " .emp_name").children(".error-icon").remove();
    eval("pageContent" + String(currentPage)).each(function(x){
        if(x.emp_id == emp_id){
            x.error = 1;
            employee_name = x.name;
        }
    })

    j("tr#" + emp_id).addClass("error_row");
    j("tr#" + emp_id).children("th.emp_name").css({
        background:"#fff2f3"
    })

    j("tr#" + emp_id + " .emp_name").prepend("<div class='error-icon'></div>" );

    j("tr#" + emp_id + " .emp_name").children(".error-icon").attr("tooltip", error_text);

}


// make the cell editable


makeTdEditable = function(ele){
    var curr_ele_id = j(ele).parent().attr("id");
    var current_value = j(ele).text();
    var parent_td = j(ele).parent('td');
    var inputDiv =  j('<input/>', {
        type: 'text',
        value: current_value
    });

    parent_td.html(inputDiv);
   
    parent_td.attr({
        input_val: current_value
    })

    j.each(j("td.cat_amount").has("input"),function(){
        j(this).parent('tr').removeClass("td_hover");
        j(this).parent('tr').children('th').removeClass("td_hover");
        var prev_val = j(this).attr("input_val");
        var curr_val = j(this).children("input").val();

        if (prev_val != curr_val){
            j(this).parent('tr').children("td:last").html("<a onclick='resetEmployeeRowConfirmation(this)'>Reset</a>")
        }
        parent_id = j(this).attr("id");
        var val = j(this).children("input").val();
        j(this).attr({
            "input_val": val
        })
        if (parent_id != curr_ele_id){
            var amount = val;
            j(this).html("<span onclick='makeTdEditable(this)'>" + amount + "</span>");
        }
    })

    j(parent_td).parent('tr').addClass("td_hover");
    j(parent_td).parent('tr').children('th').addClass("td_hover");
}


// recalculate the salary while categories are edited or while new category is created

recalculateSalary = function(ele){
    var row = j(ele).parent().parent('tr');
    var emp_id = j(row).attr("id");
    var tot_earning = 0.0;

    j.each(j(row).children('td.cat_amount[id*="earnings"]').children('span,input'), function(i,v){
        val = j(v).text() || j(v).val();
        if (val != "-")
            tot_earning+= parseFloat(val);
    })
    j(row).children("td.tot_earning").text(tot_earning.toFixed(precision));

    var tot_deduction = 0.0;
    j.each(j(row).children('td.cat_amount[id*="deductions"]').children('span,input'), function(i,v){
        val = j(v).text() || j(v).val();
        if (val != "-")
            tot_deduction+= parseFloat(j(v).text() || j(v).val());
    })

    j(row).children("td.tot_deduction").text(tot_deduction.toFixed(precision));

    netPay = tot_earning - tot_deduction;
    j(row).children("td.net_pay").text(netPay.toFixed(precision));

    if ( netPay < 0){
        markErrorRow(emp_id, t.net_pay_cannot_be_negative);
    }
    else{
        removeErrorRow(emp_id)
    }
}



// remove the errors from row if net pay is more

removeErrorRow = function(emp_id){
    j("tr#" + emp_id + " .emp_name").children(".error-icon").remove();
    j("tr#" + emp_id).removeClass("error_row");
    j("tr#" + emp_id).children("th.emp_name").css({
        background:"white"
    })
    eval("pageContent" + String(currentPage)).each(function(x){
        if(x.emp_id == emp_id){
            x.error = 0;
            employee_name = x.name;
        }
    })
}

// reset the entire table to initial state

resetEntireTable = function(){
    showConfirmation();
    j("#modalMsg1 #MB_caption").html(t.reset_changes);
    j("#msg").html(t.reset_all_warning);
    j("#ok_btn").attr('onclick', 'resetAllEmployeeRow();');
}

// confirmation for reset

showConfirmation = function(){
    document.getElementById("overlay").style.height = document.body.clientHeight + 'px';
    document.getElementById("overlay").style.display = 'block';
    document.getElementById("overlay").className = "FullOverlayEffect";
    document.getElementById("modalMsg1").className = "ShowModal";
    if(dir_flag)
        j('#modalMsg1').css({
            left : (j('body').width() - j('#modalMsg1').width())/2
        });
    else
        j('#modalMsg1').css({
            right : (j('body').width() - j('#modalMsg1').width())/2
        });
}


resetAllEmployeeRow = function(){
    removeConfirmation();
    withOverlay(function(){
        drawTable(JSON.parse(json_data));
        if(currentPage != 1 && page_number > 1){
            var evt = new MouseEvent("click", {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: 20
            }),
            ele = j(".pagination li a")[1];
            ele.dispatchEvent(evt);
        }
    });
}

// remove confirmation for reset
removeConfirmation = function(){
    document.getElementById("modalMsg1").className = "HideModal";
    document.getElementById("overlay").className = "";
    document.getElementById("overlay").style.height = '0px';
    j("#overlay").html("")
}

resetEmployeeRowConfirmation = function(ele){
    element = ele;
    showConfirmation();
    j("#modalMsg1 #MB_caption").html(t.reset_changes);
    j("#msg").html(t.reset_employee_warning);
    j("#ok_btn").attr('onclick', 'resetEmployeeRow();');
}


// reset the indiviual employee
resetEmployeeRow = function(){
    parent_row_id = j(element).parent().parent().attr("id");
    backup_data = JSON.parse(JSON.stringify(backup));
    var arr = j.map(JSON.parse(JSON.stringify(backup)).tbody, function(el) {
        return el
    });
    arr.each(function(x){
        if (x["emp_id"] == parent_row_id) old_val = x;
    })
    eval("pageContent" + String(currentPage)).each(function(x,i){

        if (x.emp_id == parent_row_id){
            temp2 = eval("pageContent" + String(currentPage) + "["+ i + "]['earnings']");
            temp1 = old_val['earnings'];
            j.each(eval("pageContent" + String(currentPage) + "["+ i + "]['earnings']"), function(a,b){
                temp2[a] = JSON.parse(temp1[a]);
            })

            temp2 = eval("pageContent" + String(currentPage) + "["+ i + "]['deductions']");
            temp1 = old_val['deductions'];
            j.each(eval("pageContent" + String(currentPage) + "["+ i + "]['deductions']"), function(a,b){
                temp2[a] = JSON.parse(temp1[a]);
            })

            temp2 = eval("pageContent" + String(currentPage) + "["+ i + "]['individual_deductions']");
            temp1 = old_val['individual_deductions'];
            j.each(eval("pageContent" + String(currentPage) + "["+ i + "]['individual_deductions']"), function(a,b){
                tt = temp2[a];
                temp2[a] = [tt[0], "0"]
            })
            
            temp2 = eval("pageContent" + String(currentPage) + "["+ i + "]['individual_earnings']");
            temp1 = old_val['individual_earnings'];
            j.each(eval("pageContent" + String(currentPage) + "["+ i + "]['individual_earnings']"), function(a,b){
                tt = temp2[a];
                temp2[a] = [tt[0], "0"]
            })

            eval("delete pageContent" + String(currentPage) + "["+ i + "].reset_status")
           
        }
    })

    
    content = eval("pageContent" + currentPage);
    drawTableBody(content);
    removeConfirmation();
}

// hide individaul category model box
removeIndividualCategoryConfirmation = function(id){
    ele_id = id;
    showConfirmation();
    j("#MB_caption").html("Remove category");
    j("#msg").html(t.do_you_want_to_remove_category);
    j("#ok_btn").attr('onclick', 'removeIndividualCategory();');
}

// show dialogue box for saving

showSaveDialogueBox = function(){
    currentR = 1;
    cancelFlag = 0;
    finished_saving = 0;
    updateSelectedStatus();
    var saveWindow = j('<div/>', {
        'class': 'save_modal_box'
    })

    var header = j('<div/>', {
        'class': 'mb_header'
    }).appendTo(saveWindow);

    var headerText = j('<p/>', {
        'text': t.generate_payslips
    }).appendTo(header);

    var body = j('<div/>', {
        'class': 'mb_body'
    }).appendTo(saveWindow);

    var footer = j('<div/>', {
        'class': 'mb_footer'
    }).appendTo(saveWindow);

    j("#page-yield").append(saveWindow);
    document.getElementById("overlay").style.height = document.body.clientHeight + 'px';
    document.getElementById("overlay").className = "FullOverlayEffect";

    error_emp_count = 0;
    for (i=1; i<=totNumber; i++){
        eval("pageContent" + String(i)).each(function(x){
            if(x.error == 1 && x.checked == 1){
                error_emp_count+=1;
            }
        })
    }
    if (error_emp_count > 0){
        saveDialogueWithErrors();
    }
    else{
        saveDialogueWithNoErrors();
    }

    if(dir_flag)
        j('.save_modal_box').css({
            left : (j('body').width() - j('.save_modal_box').width())/2
        });
    else
        j('.save_modal_box').css({
            right : (j('body').width() - j('.save_modal_box').width())/2
        });
}

// show the dialogue box if there is any error in payslips

saveDialogueWithNoErrors = function(){

    var bodyText = j('<p/>', {
        'text': t.are_you_sure_to_generate
    }).appendTo(".mb_body");

    var ok_button = j('<p/>', {
        'text': t.ok,
        id: "ok_btn",
        "class": "submit-button"
    }).appendTo(".mb_footer");

    j(ok_button).click(function(){
        saveEmployeePayslips();
    })
    var cancel_button1 =  j('<p/>', {
        'text': t.cancel,
        id: "cancel_btn",
        "class": "submit-button"
    }).appendTo(".mb_footer");

    j(cancel_button1).click(function(){
        cancelFlag = 1;
        document.getElementById("modalMsg").className = "HideModal";
        document.getElementById("overlay").className = "";
        document.getElementById("overlay").style.height = '0px';
        j("#overlay").html("")
        j(".save_modal_box").remove();
    
    })

}

// show the dialogue box if there is no errors in payslips

saveDialogueWithErrors = function(){
    
    var warning1 = j('<div/>', {
        "id":"warning1",
        text: t.payslips_cannot_be_generated_for + " "+String(error_emp_count) + " " +t.selected_employees.toLowerCase() + "." + t.please_check_payroll_entries
    }).appendTo(".mb_body");

    if(selectEmpCount - error_emp_count > 0){

        var warning2 = j('<div/>', {
            "id":"warning2",
            text: t.ignore_and_generate + String(selectEmpCount - error_emp_count) + " "+t.selected_employees.toLowerCase()
        }).appendTo(".mb_body");
    }
    var review_button =  j('<div/>', {
        "id": "review_btn",
        text: t.review_payroll,
        'class': "submit-button"
    }).appendTo(".mb_footer");

  
    if(selectEmpCount - error_emp_count > 0){
        var generate_button = j('<div/>', {
            "id": "generate_btn",
            text: t.ignore_and_generate_text,
            'class': "submit-button"
        }).appendTo(".mb_footer");

        j(generate_button).click(function(){
            j("#generate_btn").remove();
            j("#review_btn").remove();
            saveEmployeePayslips();
        })
    }else{
        j("#warning2").hide();
    }
   

    var cancel_button2 =  j('<div/>', {
        "id": "cancel_btn",
        text: t.cancel,
        'class': "submit-button"
    }).appendTo(".mb_footer");



    j(cancel_button2).on("click", function() {
        if (typeof currentRequest != 'undefined'){
            currentRequest.transport.abort();
        }
        cancelFlag = 1;
        document.getElementById("overlay").hide();
        failedEmpStatus = 0;
        savedEmpStatus = 0;
        response["tbody"] = savedState.flatten();
        savedState = [];
        currentR = page_number + 1;
        j(".save_modal_box").remove();
        document.getElementById("overlay").removeClassName("FullOverlayEffect");
        document.getElementById("overlay").style.height = '0px';
        sortData();
        content = eval("pageContent1")
        drawTableBody(content);
        if(page_number > 1){
            var evt = new MouseEvent("click", {
                view: window,
                bubbles: true,
                cancelable: true,
                clientX: 20
            }),
            ele = j(".pagination li a")[1];
            ele.dispatchEvent(evt);
        }
    
    })




    j(review_button).click(function(){
        j(".save_modal_box").hide();
        document.getElementById("overlay").hide();
    })


}


// save Employee payslips

saveEmployeePayslips = function()

{

        savedEmpStatus = 0;
        failedEmpStatus = totEmpCount - j.unique(savedArr).length;

        savedState.flatten().each(function(v,i){
            if(!v.status && v.saved == 1){
                savedEmpStatus += 1;
                savedArr.push(v.emp_id);
            }

            if(v.error && v.checked == 1){
                failedEmpStatus += 1
            }
        })
        

        var newContent = document.createElement("div")


        if (finished_saving != 1){
            info_note = t.generating_payslips_of_payroll_group + ' <b>' + pgName + '<b/>'
        }else{
            info_note = t.payslips_generated_of_payroll_group + ' <b>' + pgName + '<b/>'
        }
        var  newText = j('<p/>', {
            'html': info_note,
            "class": "new_text"
        }).appendTo(newContent);

        var  newText1 = j('<p/>', {
            'html':t.for_pay_period + ' <b>' + date_range + '<b/>',
            "class": "new_text1"
        }).appendTo(newContent);


        var loader = j('<p/>', {
            "class": "loader"
        }).appendTo(newContent);

        j(loader).append('<img align="absmiddle" alt="Loader" border="0" id="loader1" src="/images/loader.gif?1430282657">')


        var generatedStatus = j('<p/>', {
            'text':t.payslips_generated+": " + String(savedEmpStatus) + t.of + String(selectEmpCount) + ' ' + t.employees,
            "class": "success"
        }).appendTo(newContent);

        if (failedEmpStatus != 0){
            var failedStatus = j('<p/>', {
                'text':t.payslips_failed+": " + String(error_emp_count) +  t.of + String(selectEmpCount) + ' ' + t.employees,
                "class": "failed"
            }).appendTo(newContent);
        }

        if (finished_saving != 1){
            var warning = j('<p/>', {
                'text':t.pls_dont_refresh_or_press_back_button,
                "class": "warning"
            }).appendTo(newContent);
        }


        j(".mb_body").html(newContent);
        j(".mb_footer #ok_btn").hide();
        j(".mb_footer #review_btn").hide();
        j(".mb_footer #generate_btn").hide();
        if (finished_saving == 1){
            j("#cancel_btn").off("click");
            j("#cancel_btn").text(t.ok).attr("id", "finished_bttn");
            j(".mb_body p.loader").html("<div class='tick symbol'></div>")
            j("#finished_bttn").click(function(){
                if (failedEmpStatus > 0 || failedEmpStatus < 0){
                    cancelEmployeePayslips();
                }else{
                    url = window.location.origin +"/employee_payslips/generate_payslips/" + String(pgId) + "?end_date=" + String(eDate) + "&start_date=" + String(sDate)
                    window.location.replace(url)
                }
            })
        }

        bck = eval("pageContent" + String(currentR));
        payslips = eval("pageContent" + String(currentR)).collect(function(e){
            if(e.saved == 0 && e.error == 0 && e.checked == 1) return e
        }).filter(Boolean);
        emp_ids = payslips.collect(function(e){
            return e.emp_id
        })
        bck = bck.collect(function(e){
            if(emp_ids.indexOf(e.emp_id) == -1 ) return e;
        }).filter(Boolean);
        if(currentR <= page_number && cancelFlag != 1 && payslips.length > 0){
            currentRequest = new Ajax.Request('/employee_payslips/save_employee_payslips.json',{
                parameters: {
                    employee_payslips: JSON.parse(JSON.stringify(payslips)),
                    start_date: sDate,
                    end_date: eDate,
                    payroll_group_id: pgId
                },
                asynchronous:true,
                evalScripts:true,
                method:'post',
                processData: false,
                onComplete:function(resp){
                    x = currentR;
                    currentR++;
                    if(currentR <= page_number){
                        savedState.push(resp.responseJSON.filter(function(e) {
                            return e!=null
                        }))

                        savedState.push(bck.filter(function(e) {
                            return e!=null
                        }))
                        
                        if (cancelFlag == 1)
                            cancelEmployeePayslips();
                        else
                            saveEmployeePayslips();
                    }
                    else{
                        finished_saving = 1;                    
                        savedState = savedState.concat(resp.responseJSON.filter(function(e) {
                            return e!=null
                        }))
                        savedState = savedState.flatten().concat(bck);
                        if (cancelFlag == 1)
                            cancelEmployeePayslips();
                        else
                            saveEmployeePayslips();
                    }
                   
                }
            });
        }else{
            if(payslips.length == 0 && currentR < page_number ){
                x = currentR;
                currentR++;
                y = eval("pageContent" + String(x));
                y.concat(bck);

                savedState.push(bck.filter(function(e) {
                    return e!=null
                }))

                saveEmployeePayslips();
            }else{
                y = eval("pageContent" + String(x));
                y.concat(bck);

                savedState.push(bck.filter(function(e) {
                    return e!=null
                }))
                finished_saving = 1;
                j("#cancel_btn").off("click");
                j("#cancel_btn").text(t.ok).attr("id", "finished_bttn");
                j(".mb_body p.loader").html("<div class='tick symbol'></div>")
                j("#finished_bttn").click(function(){
                    if (failedEmpStatus > 0 || failedEmpStatus < 0){
                        cancelEmployeePayslips();
                    }else{
                        url = window.location.origin +"/employee_payslips/generate_payslips/" + String(pgId) + "?end_date=" + String(eDate) + "&start_date=" + String(sDate)
                        window.location.replace(url)
                    }
                })
                
            }
        }
    }


removeIndividualCategory = function() {
    var cat_path = ele_id.split("-");
    var type = cat_path[0];
    var cat_id = cat_path[1];
    for (i=1; i<=totNumber; i++){
        eval("pageContent" + String(i)).each(function(x){
            eval("delete x." + type + "["+cat_id+"]" )
        })
    }

    var intermediate = JSON.parse(intermediateData.tbody);

    intermediate.each(function(x){
        eval("delete x." + type + "["+cat_id+"]" )
    })

    intermediateData.tbody = JSON.parse(JSON.stringify(intermediate));


    var original = JSON.parse(originalData.tbody);

    original.each(function(x){
        eval("delete x." + type + "["+cat_id+"]" )
    })

    originalData.tbody = JSON.parse(JSON.stringify(original));
    
    eval("delete currentData.theader." + type + "["+cat_id+"]"  )
    eval("delete originalData.theader." + type + "["+cat_id+"]"  )
    drawTableHeader();
    drawTableBody(pageContent1);
    j.each(j("td.cat_amount span"),function(){
        recalculateSalary(this);
    })
    recalculateNetPay();
    removeConfirmation();

}



cancelEmployeePayslips = function(){
    savedState.flatten().each(function(v){
        if(v.saved == 1)
        savedArr.push(v.emp_id);
    })
    if(savedEmpStatus == totEmpCount){
        url = window.location.origin +"/employee_payslips/generate_payslips/" + String(pgId) + "?end_date=" + String(eDate) + "&start_date=" + String(sDate)
        window.location.replace(url)
        return
    }
    j(".save_modal_box").remove();
    document.getElementById("overlay").removeClassName("FullOverlayEffect");
    document.getElementById("overlay").style.height = '0px';
    
    withOverlay(function(){
        
        for (i=1; i<=totNumber; i++){
            if (eval("pageContent"+String(i)) != undefined)
                eval("pageContent" + String(i)).each(function(x){
                    if(x.saved == 0)
                        savedState.push(x);
                })
        }
        response["theader"] = currentData.theader;
        response["tbody"] = savedState.flatten().uniq();
        savedState = [];
        failedEmpStatus = 0;
        savedEmpStatus = 0;
        currentR = 1;
        cancelFlag = 0;

        drawTable(response);
    })


}


// recalculate net pay
recalculateNetPay = function(){
    var tot_earning = 0;
    var tot_deduction = 0;
    for (i=1; i<=totNumber; i++){
        eval("pageContent" + String(i)).each(function(x){
            j.each(x.earnings,function(key,val){
                tot_earning += parseFloat(val[1]);
            })

            j.each(x.deductions,function(key,val){
                tot_deduction += parseFloat(val[1]);
            })

            j.each(x.individual_earnings,function(key,val){
                tot_earning += parseFloat(val[1]);
            })

            j.each(x.individual_deductions,function(key,val){
                tot_deduction += parseFloat(val[1]);
            })

            x.net_pay = tot_earning - tot_deduction;
            if(x.net_pay < 0){
                x.error = 1
            }
            else{
                x.error = 0
            }
        
        })
    }
}
