function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  j("." + String(association)).append(content.replace(regexp, new_id));
}


function remove_fields(link, association){
   $(link).previous("input[type=hidden]").value='1';
   console.log($(link));
   console.log("#" + String(association));
   $(link).up("#" + String(association)).hide();
   j(j('table.sold_items tr')[2]).show();
   j(j(j('table.sold_items tr')[2]).children().last().children().children()[0]).val("0");
   j(j('table.additional_charges tr')[2]).show();
   j(j('table.discounts tr')[2]).show();

}


function precision(value, amount){
   amount = parseFloat(amount)
   return amount.toFixed(value);
}

