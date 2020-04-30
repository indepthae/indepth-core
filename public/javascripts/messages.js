var j = jQuery.noConflict();

$attachment_error = false;

valid_attachments = [ 'image/png','image/jpg','image/jpeg','image/gif','image/bmp','application/pdf',
    'application/powerpoint','application/mspowerpoint','application/vnd.ms-powerpoint',
    'application/x-mspowerpoint','application/msword','application/mspowerpoint',
    'application/vnd.ms-powerpoint','application/excel','application/vnd.ms-excel',
    'application/x-excel','application/x-msexcel','application/rtf','application/x-rtf',
    'text/richtext','text/plain','application/wordperfect','application/x-wpwin',
    'text/tab-separated-values','text/csv','application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.slideshow','application/vnd.oasis.opendocument.text',
    'application/vnd.oasis.opendocument.spreadsheet','image/svg+xml','application/vnd.ms-works','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/wpd','application/wordperf'
]
close_modal_box = function () {
  j('.autocomplete-w1').hide();
  remove_popup_box();
  $attachment_error = false
}

set_lock = function () {
lock = true
}

j(document).delegate("#new_message #query_message", "input", function () {
  set_delay(function () {
      search_message_ajax()
  }, 400);
});

var set_delay = (function () {
  var timer = 0;
  return function (callback, ms) {
      clearTimeout(timer);
      timer = setTimeout(callback, ms);
  };
})();

load_hide_function = function () {
  lock = false;
  j('#popup_content #query_message').focusout(function () {
      if (j('.no_users').length > 0) {
          j('#search_list').hide();
      }
  })
}

function insert_recipient_fallback(data) {
  data = data.replace(/'/g, '"')
  data = jQuery.parseJSON(data)
  console.log(data)
}

function insert_element_and_check_parent(e) {
    data_el = j(e).find('div.data_cont').first()
    id = data_el.attr('data-id')
    receiver = data_el.attr('data-receiver')

    j('<input>').attr({type: 'hidden', value: id, id: 'recipient_' + id, name: 'message_thread[messages_attributes[0[message_recipients_attributes[' + id + '[recipient_id]]]]]'}).appendTo('form');
    insert_recipient_data(e, id, receiver)
}

function insert_recipient_data(e, id, receiver) {
    j('#search_list').hide();
    j('#query_message').hide();
    j(e).attr('onclick', '').unbind('click');
    j('#popup_content #msg-receivers').addClass('recipient_' + id);
    j(e).appendTo('#popup_content #msg-receivers');
    remove_el = '<span id="remove_recipient" onclick="remove_recipient(' + id + ')"></span>'
    j(remove_el).insertAfter('.recipient_' + id + ' .name_and_tag')
    j('#popup_content #msg-receivers').css("display", "block");
    if (receiver == 'student') {
      j.ajax({
          type: 'GET',
          url: "/messages/check_parent",
          data: {
              student_id: id
          },
          success: function (resp) {
              //  if(resp == 'true'){
              //    create_parent_select();
              //  }
          }
      });
    }
}
function remove_fields(link) {
    console.log(j(link).closest(".paperclip_field"));
    j(link).prev("input[type=hidden]").val("1");
    j(link).closest(".fields").remove();
    j(".add_button_img").show();
    att_div = j('#attachment-field-div').height();
    message_thread = j("#message_threads").height();
    thread_listing = j("#thread_listing_main").height();
    j("#message_threads").css("height", message_thread - att_div + "px");
    j("#thread_listing_main").css("height", thread_listing - att_div + "px");

  }
  function add_fields(link,association,content,view) {
    if (j(".fields:visible").length <5){
      if (j(".fields:visible").length>=4){
        j(".add_button_img").hide();
      }    
      var new_id = new Date().getTime();
      var regexp = new RegExp("new_" + association, "g")
      j(link).parent().before(content.replace(regexp, new_id));
      att_div = j('#attachment-field-div').height();
      message_thread = j("#message_threads").height();
      thread_listing = j("#thread_listing_main").height();
      j("#message_threads").css("height", message_thread + att_div + "px");
      j("#thread_listing_main").css("height", thread_listing + att_div + "px");
    }
  }
  
function show_attachment_error(){
    j('#popup_content #attachment_error').css("display", "block");
}


function validate_upload_type(input) {
    for( var i = 0;i<input.files.length;i++){
        if (input.files && input.files[i]) {
            if(j.inArray(input.files[i].type, valid_attachments) == -1){
                //show_attachment_error()
                $attachment_error = true
            }else{
                $attachment_error = false
            }
        }
    }
}

remove_recipient = function (id) {
    j('.recipient_' + id).empty();
    $$('#recipient_' + id).each(function (el) {
      el.remove();
    });
    j('#popup_content #msg-receivers').css("display", "none");
    j('#query_message').val("");
    j('#query_message').show();
    j('#parent_select').html("");
}



function remove_model_uploaded_file() {
    resetFileElement(j(".message_popup #field_message_thread_messages_attributes_1_message_attachment_attributes_attachment"));
    resetFileElement(j(".message_popup #message_thread_messages_attributes_1_message_attachment_attributes_attachment"));
    $attachment_error = false
    j('#popup_content #attachment_error').css("display", "none");
}

function resetFileElement(e) {
    console.log(e.attr('id'))
    e.wrap('<form>').closest('form').get(0).reset();
    reset_values();
    e.unwrap();
}

//Notifications

mark_notifications_read = function (e) {
  j.ajax({
      type: 'GET',
      url: "/notifications/mark_notification_read",
      beforeSend : function() {
        show_notification_overlay();
      },
      success: function (resp) {
        j(".notification_overlay").fadeOut();
        j('#loader_notification').css('display','none');
        if(resp == 'success'){
          j('.notification_links').css('display','none');
          j('#notification-link-img').html('');
          j('#notification_list').html('<div id="no_unread_noti">No Unread Notifications</div>')
        }
      }
  });
}

show_notification_overlay = function(){
    var $container = j("#show-notification");
    j(".notification_overlay").fadeIn().css("top", $container.scrollTop() + "px");
    height = j('.notification_overlay').height() / 2;
    width = (j('.notification_overlay').width() / 2) - 17;
    j('#loader_notification').css('top',height);
    j('#loader_notification').css('left',width);
    j('#loader_notification').css('display','block');
}