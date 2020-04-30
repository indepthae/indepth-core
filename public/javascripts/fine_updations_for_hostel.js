function fine_updation(date,balance) {

    var payment_date= new Date(j('#transaction_date').val()).getTime()
    var due_date=new Date(date).getTime()
    if (j('.cancel-fine').length == 1) {
        var precision = parseInt("<%= @precision %>");
        fine = parseFloat(j('#fine').text())
        fine_amount_updations(fine, 'subtract', precision,balance)
        j('#show-fine').text("")
        j("#fees_amount").removeAttr('tooltip')
        j("#fees_amount").removeAttr('readonly')
        j('[id^="hidden_fine_amount"]').remove();
        j('[id^="hidden_fine_included"]').remove();
    }

    if ( (payment_date <= due_date)) {

        j('#fine-slab').hide();
    }
    else if (payment_date > due_date){
        j('#fine-slab').show();
    }
}

function fine_amount_updations(fine, operator, precision,balance) {
    fine = parseFloat(fine)
    total_fees = parseFloat(j("#total-fees").text())
    amount_pay = parseFloat(j("#fees_amount").val())

    j("#total-fees").text(add_or_subtract(operator, total_fees, fine).toFixed(precision))
    j("#fees_amount").val(balance)

}
function add_or_subtract(operator, element1, element2) {

    switch (operator) {
        case "add":
            return element1 + element2
        case "subtract":
            return element1 - element2
    }

}