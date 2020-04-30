 function show_print_dialog(student_id) {
    var iframe = document.getElementById('tc_printer_template_container');
    j('#tc_printer_template_container').css('display','block');
    j('#tc_printer_template_container').css('visibility','hidden');
    j('#tc_printer_template_container').css('position','absolute');
    j('#tc_printer_template_container').unbind();
    j('#tc_printer_template_container').load(function(){
      var iframe_window = (iframe.contentWindow || iframe.contentDocument);
      result=iframe_window.document.execCommand('print', false, null) || iframe_window.print();
    });
    iframe.src=window.location.origin+"/tc_template_generate_certificates/transfer_certificate_download?student_id="+student_id;
  }
  
  function show_print_preview() {
    var iframe = document.getElementById('tc_printer_template_container');
    j('#tc_printer_template_container').css('display','block');
    j('#tc_printer_template_container').css('visibility','hidden');
    j('#tc_printer_template_container').css('position','absolute');
    j('#tc_printer_template_container').unbind();
    j('#tc_printer_template_container').load(function(){
      var iframe_window = (iframe.contentWindow || iframe.contentDocument);
      result=iframe_window.document.execCommand('print', false, null) || iframe_window.print();
    });
    iframe.src=window.location.origin+"/tc_templates/current_tc_preview";
  }

