$(function () {
  $('.select2').select2({ allowClear: true });

	$( document ).ready(function () {
		isForm('contract', true, true);

    $(document).on("submit", "form", function(e){
      if ($("#contract_products").val() == null) {
        $('#products_form_group').addClass("has-error");
        $('#products_form_group').attr("data-content", "Can't be blank");
        $("#scroll-up").trigger("click");
        $('.has-error').popover({
      		trigger: 'hover',
      		placement: 'bottom',
      		animation: true
      	});
        e.preventDefault();
        return false;
      }
    });

		$('.numeric').keypress(function (e) {
			 if (e.which != 8 && e.which != 0 && (e.which < 48 || e.which > 57)) return false;
		});

    $('.positive-numeric').on('change', function () {
      var value = $(this).val();
      if (value < 0) $(this).val(0);
    });

		if ($('#client_approve_block .icheckbox_minimal-blue.checked').length > 0) {
			$('#client_approve_block').show();
			$('#client_approval_div .icheckbox_minimal-blue ins').trigger('click');
		}

		$('#client_approval_div ins, #client_approval_div label').on('click', function() {
			if ($('#client_approval_div .icheckbox_minimal-blue').hasClass('checked')) {
				$('#client_approve_block').show();
			} else {
				$('#client_approve_block .icheckbox_minimal-blue.checked ins').trigger('click');
				$('#client_approve_block').hide();
			}
		});

		$('#client_approve_block ins, #client_approve_block label').on('click', function() {
			var hasApproveCheckedBlock = $('#client_approve_block .icheckbox_minimal-blue.checked').length > 0;
			var hasApproveCheckedDiv = $('#client_approval_div .icheckbox_minimal-blue').hasClass('checked');
			if (hasApproveCheckedBlock) {
				 if (!hasApproveCheckedDiv) $('#client_approval_div .icheckbox_minimal-blue ins').trigger('click');
			} else {
				 if (hasApproveCheckedDiv) $('#client_approval_div .icheckbox_minimal-blue ins').trigger('click');
			}
		});

		if ($('#client_supply_block .icheckbox_minimal-blue.checked').length > 0) {
			$('#client_supply_block').show();
			$("#client_supply_div .icheckbox_minimal-blue ins").trigger('click');
		}

		$('#client_supply_div ins, #client_supply_div label').on('click', function() {
			if ($('#client_supply_div .icheckbox_minimal-blue').hasClass('checked')) {
				$('#client_supply_block').show();
			} else {
				$('#client_supply_block .icheckbox_minimal-blue.checked ins').trigger('click');
				$('#client_supply_block').hide();
			}
		});

		$('#client_supply_block ins, #client_supply_block label').on('click', function() {
			var hasSupplyCheckedBlock = $('#client_supply_block .icheckbox_minimal-blue.checked').length > 0;
			var hasSupplyCheckedDiv = $('#client_supply_div .icheckbox_minimal-blue').hasClass('checked');
			if (hasSupplyCheckedBlock) {
				 if (!hasSupplyCheckedDiv) $('#client_supply_div .icheckbox_minimal-blue ins').trigger('click');
			} else {
				 if (hasSupplyCheckedDiv) $('#client_supply_div .icheckbox_minimal-blue ins').trigger('click');
			}
		});
	});
});
