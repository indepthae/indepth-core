function show_print_dialog() {
    transaction_ids = Array.prototype.slice.call(arguments)[0];
    detailed = (Array.prototype.slice.call(arguments)[1] == true) ? true : false;
    
    //console.log(transaction_ids);
    
    var iframe = document.getElementById('receipt_printer_template_container');
    
    j('#receipt_printer_template_container').unbind();
    
    j('#receipt_printer_template_container').load(function () {
        var iframe_window = (iframe.contentWindow || iframe.contentDocument);
        result = iframe_window.document.execCommand('print', false, null) || iframe_window.print();
    });
    
    var obj = {transaction_id: transaction_ids, detailed: detailed};
    
    iframe.src = window.location.origin + "/finance/generate_fee_receipt?" + j.param(obj);
    // iframe.src=window.location.origin+"/finance/generate_fee_receipt?transaction_id="+transaction_id;
}

function set_width_in_firefox(width) {
    var isFirefox = typeof InstallTrigger !== 'undefined';   // Firefox 1.0+
    if (isFirefox) {
        j(".receipt-container").css("width", width);
        j(".header-content").css("width", "542px");
        // j("body").css("font-size","12px");
    }
}
