$(document).ready(function(){
	$('#tabs').tabs({cookie:{expires:1}});
	$('#create_user').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Create User": function(){
				$("#create_user_form").submit();
			},
			Cancel: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#modify_user').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Save User": function(){
				$("#modify_user_form").submit();
			},
			Cancel: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#delete_user').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Delete User": function(){
				$('#delete_user').dialog('close');
				$("#delete_user_form").submit();
			},
			Cancel: function(){
				$(this).dialog("close");
			}
		}
	});
	$('#delete_user_failed').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			Ok: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#create_problem').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Create Problem": function(){
				$("#create_problem_form").submit();
			},
			Cancel: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#modify_problem').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Save Problem": function(){
				$("#modify_problem_form").submit();
			},
			Cancel: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#delete_problem').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Delete Problem": function(){
				$('#delete_problem').dialog('close');
				$("#delete_problem_form").submit();
			},
			Cancel: function(){
				$(this).dialog("close");
			}
		}
	});
	$('#submit_problem').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Submit Problem": function(){
				//$('#submit_problem').dialog('close');
				$("#submit_problem_form").submit();
			},
			Cancel: function(){
				$(this).dialog("close");
			}
		}
	});
	$('#delete_problem_failed').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			Ok: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#clear_submissions_dialog').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Clear All Submissions": function(){
				$('#clear_submissions_dialog').dialog('close');
				$("#clear_submissions_form").submit();
			},
			Cancel: function(){
				$(this).dialog("close");
			}
		}
	});
	$('#c_sub_failed').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			Ok: function(){
				$(this).dialog('close');
			}
		}
	});
	$('#delete_sub').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			"Delete Submission": function(){
				$('#delete_sub').dialog('close');
				$("#delete_sub_form").submit();
			},
			Cancel: function(){
				$(this).dialog("close");
			}
		}
	});
	$('#delete_sub_failed').dialog({
		resizable: false,
		autoOpen:false,
		modal: true,
		width: 'auto',
		buttons: {
			Ok: function(){
				$(this).dialog('close');
			}
		}
	});
	
	var userEdit = function(e){
		var a = $(this)[0];
		var s = "";
		for(var i in a){s += " " + i;}
		var row = $(this)[0].attributes['value'].value;
		var whole_row = $("#row_" + row + " td");

		$('#modify_user input[name="u_id"]')[0].value = whole_row[0].innerText;
		$('#modify_user input[name="username"]')[0].value = whole_row[1].innerText;
		
		var type = whole_row[4].innerText;
		$('#m_user_type')[0].innerText = type;
		if(type == 'Team'){
			$('#modify_user input[name="team_name"]').removeAttr('disabled')[0].value = whole_row[2].innerText;
			$('#modify_user input[name="school"]').removeAttr('disabled')[0].value = whole_row[3].innerText;
		}else{
			$('#modify_user input[name="team_name"], #modify_user input[name="school"]')
								.attr('disabled','disabled')
								.val('');
		}
		
		$("#modifyUserErrorMessage").hide();
		$('#modify_user').dialog('open');
	};

	var userDelete = function(e){
		var row = $(this)[0].attributes.getNamedItem('value').value;
		var u_id = $("tr#row_"+row+" td.u_id")[0].innerText;
		var username = $("tr#row_"+row+" td.username")[0].innerText;
		$('strong#d_user_username')[0].innerText = username;
		$('#delete_user_u_id')[0].value = u_id;
		$('#deleteUserError').hide();
		$('#delete_user').dialog('open');
	};
	
	var problemSubmit = function(e){
		try{
			new FormData();
			
			var p_id = $(this)[0].attributes.getNamedItem('value').value;
			var problemname = $("h3#problem_head_" + p_id + " div.problemname")[0].innerText;
		
			$('#submit_problem').dialog('option','title',"Submit Problem: " + problemname);
			$('#submit_problem_p_id').val(p_id);
			$('#submit_problem_form')[0].reset()
			$('#submitProblemErrorMessage').hide();
			$('#submit_problem').dialog('open');
		}catch(e){
			alert("Your browser does not support the 'FormData' object for uploading files.\n" + 
						"Please update to a newer version (Opera 12+/Chrome/Safari/FireFox 4+");
		}
	};
	
	var problemShow = function(e){
		var p_id = $(this)[0].attributes.getNamedItem('value').value;
		var io = $('#problem_' + p_id + ' .io');
		if(io.is(':visible')){
			io.hide();
			return;
		}
				
		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'success':function(a){
				$("#createProblemErrorMessage").hide();
				if(a.status == 0){ //failure
					//$("#createProblemErrorMessage").text(a.message).show();
				}else{
					//$("#createProblemErrorMessage").hide().text("");
					io.show();
					//var i = a.problem.input.replace(/\n/g,'<br />')
					$('.input pre', io).text(a.problem.input).show();
					$('.output pre', io).text(a.problem.output).show();
					
				}
			},
			'complete':function(a){
				//$(".c_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				//$("#showProblemErrorMessage").text("Error communicating with server.");
				//$("#showProblemErrorMessage").show();
			},
			data:{'action':'show_problem', 'p_id':p_id}
		});
	};
	
	var problemEdit = function(e){
		var p_id = $(this)[0].attributes['value'].value;
		
		var problemName = $('#problem_head_' + p_id + ' div.problemname')[0].innerText;
		
		$('#modify_problem_p_id').val(p_id);
		$('#modify_problem input[name="problemname"]')[0].value = problemName;
		$("#createProblemErrorMessage").text('').hide();
		
		$('#modify_problem').dialog('open');

	};

	var problemDelete = function(e){
		var p_id = $(this)[0].attributes.getNamedItem('value').value;
		
		var problemname = $("h3#problem_head_" + p_id + " div.problemname")[0].innerText;
		$('strong#d_problem_problemname')[0].innerText = problemname;
		$('#delete_problem_p_id')[0].value = p_id;
		$('#deleteProblemError').hide();
		$('#delete_problem').dialog('open');
	};
	
	var deleteSub = function(e){
		var s_id = $(this)[0].attributes.getNamedItem('value').value;
		
		$('strong#d_sub_s_id')[0].innerText = s_id;
		$('#delete_sub_s_id')[0].value = s_id;
		$('#deleteSubError').hide();
		$('#delete_sub').dialog('open');
	}
	
	$('#adduser').button().click(function(){
		$("#createUserErrorMessage").hide();
		//$("#create_user_form")[0].reset();
		$('#create_user').dialog('open');
	});
	$("span.user-edit-button").click(userEdit);
	$("span.user-delete-button").click(userDelete);
	$('.edit_problem').button().click(problemEdit);
	$('.del_problem').button().click(problemDelete);
	$('.show_problem').button().click(problemShow);
	$('.submit_problem').button().click(problemSubmit);
	$('#clear_submissions').button().click(function(){
		$('#clear_submissions_dialog').dialog('open');
	});
	$("span.submission-delete-button").click(deleteSub);
	
	$('select.c_user').change(function(e){
		if(this.selectedIndex != 2){
			$('#create_user input.team_field').attr('disabled','disabled');
		}else{
			$('#create_user input.team_field').removeAttr('disabled');
		}
	});

	$("#delete_problem_form").submit(function(e){
		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'success':function(a){
				$("#deleteUserError").hide();
				if(a.status == 0){ //failure
					$('#delete_problem_failed strong').text("Server error.  Problem was not deleted.");
					$('#delete_problem_failed').dialog('open');
				}else{
					//remove row from table
					var row = $('#problem_head_' + a.p_id + ', #problem_' + a.p_id).remove();
				}
			},
			'complete':function(a){
				$(".d_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$('#delete_problem_failed strong').text("Error Communicating with the server.  Problem was not deleted.");
				$('#delete_problem_failed').dialog('open');
			},
			'data': $("#delete_problem_form").serializeArray()
		});
		return false;
	});
	
	$("#create_user_form").submit(function(e){
		//verify
		
		var dirty = false;
		var req = $("#create_user_form tr");
		for(var i = 1; i < 6; i++){
			if((i<4 || req[0].children[1].firstElementChild.selectedIndex == 2) && /^\s*$/.test(req[i].children[1].children[0].value) ){
				req[i].children[2].innerText = "Required.";
				dirty = true;
			}else{
				req[i].children[2].innerText = "";
			}
		}
		if(req[3].children[2].innerText == ""  && req[2].children[1].children[0].value != req[3].children[1].children[0].value){
			req[3].children[2].innerText = "Does not match.";
			dirty = true;
		}	
		
		if(dirty){
			return false;
		}
		
		$(".c_loading").show();
		$("#createUserErrorMessage").hide();
		$("#createUserErrorMessage").text("");
		
		$.ajax({
			'type':'POST',
			'url':'manageUser.pl',
			'async':true,
			'success':function(a){
				$("#createUserErrorMessage").hide();
				if(a.status == 0){ //failure
					$("#createUserErrorMessage").text(a.message).show();
				}else{
					$("#createUserErrorMessage").hide().text("");
					var checked;
					if(!(checked = $('#c_user_keep')[0].checked)){
						$('#create_user').dialog('close');
					}
					$("#create_user_form")[0].reset();

					$('#c_user_keep')[0].checked = checked;
					
					//add row to table
					var newRow = $('#user_row_template')[0].cloneNode(true);
					newRow.id = "row_" + a.user.u_id;
					newRow.removeAttribute('style');
					$('td.u_id', newRow).html(a.user.u_id);
					$('td.username', newRow).html(a.user.username);
					$('td.team_name', newRow).html(a.user.user_type!=3?'-':a.user.team_name);
					$('td.school', newRow).html(a.user.user_type!=3?'-':a.user.school);
					$('span', newRow).attr('value', a.user.u_id);
					var type = a.user.user_type==1?'Admin':a.user.user_type==2?'Judge':'Team';
					$('td.user_type', newRow).html(type);

					$('#users_table > tbody')[0].appendChild(newRow);
					
					$("span.user-edit-button", newRow).click(userEdit);
					$("span.user-delete-button", newRow).click(userDelete);
				}
			},
			'complete':function(a){
				$(".c_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$("#createUserErrorMessage").text("Error communicating with server.");
				$("#createUserErrorMessage").show();
			},
			'data': $("#create_user_form").serializeArray()
		});
		//display errors or clear form and hide
		
		return false;
	});
	
	$("#delete_user_form").submit(function(e) {
		$.ajax({
			'type':'POST',
			'url':'manageUser.pl',
			'async':true,
			'success':function(a){
				$("#deleteUserError").hide();
				if(a.status == 0){ //failure
					$('#delete_user_failed strong').text("Server Error.  User was not deleted.");
					$('#delete_user_failed').dialog('open');
				}else{
					$("#deleteUserErrorMessage").hide().text("");
					
					$('#delete_user').dialog('close');
					$("#delete_user_form")[0].reset();
					
					//remove row from table
					var row = $('#row_' + a.u_id).remove();
				}
			},
			'complete':function(a){
				$(".d_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
			$('#delete_user_failed strong').text("Error communicating with the server.  User was not deleted.");
				$('#delete_user_failed').dialog('open');
			},
			'data': $("#delete_user_form").serializeArray()
		});
		return false;
	});
	
	$("#modify_user_form").submit(function(e){
		//verify
		var dirty = false;
		var type = $('#m_user_type')[0].innerText;
		
		if($('#modify_user_form input[name="username"]')[0].value==''){
			$('#m_username_req')[0].innerText = "Required.";
			dirty = true;
		}else{
			$('#m_username_req')[0].innerText = "";
		}
		var pw;
		if((pw = $('#modify_user_form input[name="password"]')[0].value) != '' ){
			if($('#modify_user_form input[name="password_again"]')[0].value != pw){
				$('#m_pw_rep_req')[0].innerText = "Does not match.";
				dirty = true;
			}else{
				$('#m_pw_rep_req')[0].innerText = "";
			}
		}
		if(type == 'Team'){
			if($('#modify_user_form input[name="team_name"]')[0].value == ''){
				$('#m_team_req')[0].innerText = "Required.";
				dirty = true;
			}else{
				$('#m_team_req')[0].innerText = "";
			}
			if($('#modify_user_form input[name="school"]')[0].value == ''){
				$('#m_school_req')[0].innerText = "Required.";
				dirty = true;
			}else{
				$('#m_school_req')[0].innerText = "";
			}
		}

		if(dirty){
			return false;
		}
		
		$(".m_loading").show();
		$("#modifyUserErrorMessage").hide();
		$("#modifyUserErrorMessage").text("");
		
		$.ajax({
			'type':'POST',
			'url':'manageUser.pl',
			'async':true,
			'success':function(a){
				$("#modifyUserErrorMessage").hide();
				if(a.status == 0){ //failure
					$("#modifyUserErrorMessage").text(a.message).show();
				}else{
					$("#modifyUserErrorMessage").hide().text("");
					$('#modify_user').dialog('close');
					
					$("#modify_user_form")[0].reset();
					
					//update row
					var row = $('#row_' + a.user.u_id)[0];
					row.children[1].innerText = a.user.username;
					row.children[2].innerText = a.user.team_name;
					row.children[3].innerText = a.user.school;
				}
			},
			'complete':function(a){
				$(".m_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$("#modifyUserErrorMessage").text("Error communicating with server.");
				$("#modifyUserErrorMessage").show();
			},
			'data': $("#modify_user_form").serializeArray()
		});
		//display errors or clear form and hide
		

		
		return false;
	});

	$('#problem_accordion').accordion({
		collapsible: true,
		autoHeight: false,
		navigation: true
	}).accordion("activate" , false);
	
	$('#add_problem').button().click(function(){
		try{
			new FormData();
			$('#create_problem').dialog('open');
		}catch(e){
			alert("Your browser does not support the 'FormData' object for uploading files.\n" + 
						"Please update to a newer version (Opera 12+/Chrome/Safari/FireFox 4+");
		}
	});
	
	$('#create_problem_form').submit(function(){
		
		//verify input
		var data = new FormData($('#create_problem_form')[0]);
		
		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'cache': false,
			'processData': false,
			'contentType':'multipart/form-data',
			'success':function(a){
				$("#createProblemErrorMessage").hide();
				if(a.status == 0){ //failure
					$("#createProblemErrorMessage").text(a.message).show();
				}else{
					$("#createProblemErrorMessage").hide().text("");
					var checked;
					if(!(checked = $('#c_problem_keep')[0].checked)){
						$('#create_problem').dialog('close');
					}
					$("#create_problem_form")[0].reset();

					$('#c_problem_keep')[0].checked = checked;
					
					//add row to table
					var newRow = $('#problem_row_template')[0].cloneNode(true);
					$('div.problem_content', newRow).id = "problem_" + a.problem.p_id;
					$('div.buttons a', newRow).val(a.problem.p_id);
					$('h3.problem_header div.p_id', newRow).html(a.problem.p_id);
					$('h3.problem_header div.problemname', newRow).html(a.problem.problemname);
					$('h3.problem_header', newRow)[0].id = "problem_head_" + a.problem.p_id;
					
					$('div.problem_content', newRow)[0].id = "problem_" + a.problem.p_id;
					
					$('a.del_problem', newRow).click(problemDelete)[0].attributes.getNamedItem('value').value = a.problem.p_id;
					$('a.edit_problem', newRow).click(problemEdit)[0].attributes.getNamedItem('value').value = a.problem.p_id;
					$('a.show_problem', newRow).click(problemShow)[0].attributes.getNamedItem('value').value = a.problem.p_id;

					$('#problem_accordion').append(newRow.children)
							.accordion('destroy')
							.accordion({
									collapsible: true,
									autoHeight: false,
									navigation: true
								})
							.accordion("activate" , false);
					
				}
			},
			'complete':function(a){
				//$(".c_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$("#createProblemErrorMessage").text("Error communicating with server.");
				$("#createProblemErrorMessage").show();
			},
			'data': data
		});

		return false;
	});
	
	$("#submit_problem_form").submit(function(){
		//verify input
		var data = new FormData($('#submit_problem_form')[0]);

		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'cache': false,
			'processData': false,
			'contentType':'multipart/form-data',
			'beforeSend':function(){
				$(".s_loading").show();
			},
			'success':function(a){
				$("#submitProblemErrorMessage").hide();
				if(a.status == 0){ //failure
					$("#submitProblemErrorMessage").text(a.message).show();
				}else{
					$("#submitProblemErrorMessage").hide().text("");
					$("#submit_problem_form")[0].reset();
					
					$('#submit_problem').dialog('close');
					//add row to submissions tab
				}
			},
			'complete':function(a){
				$(".s_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$("#submitProblemErrorMessage").text("Error communicating with server.");
				$("#submitProblemErrorMessage").show();
			},
			'data': data
		});

		return false;
	});
	
	$("#clear_submissions_form").submit(function(e){
		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'success':function(a){
				$("#deleteUserError").hide();
				if(a.status == 0){ //failure
					$('#c_sub_failed').dialog('open');
				}else{
					$("#clearSubErrorMessage").hide().text("");
					
					$('#clear_submissions_dialog').dialog('close');
					$("#clear_submissions_form")[0].reset();
					
					//remove row from table
					$('#submissions_table tr:not(#submission_row_template):not(.header_row)').remove();
				}
			},
			'complete':function(a){
				$(".d_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$('#c_sub_failed').dialog('open');
			},
			'data': $("#clear_submissions_form").serializeArray()
		});
		return false;
	});
	
	$("#delete_sub_form").submit(function(e){
		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'success':function(a){
				$("#deleteSubError").hide();
				if(a.status == 0){ //failure
					$('#delete_sub_failed').dialog('open');
				}else{
					//remove row from table
					$('#sub_row_' + a.s_id).remove();
				}
			},
			'complete':function(a){
				$(".d_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$('#delete_problem_failed strong').text("Error Communicating with the server.  Problem was not deleted.");
				$('#delete_problem_failed').dialog('open');
			},
			'data': $("#delete_sub_form").serializeArray()
		});
		return false;
	});
	
	$("#modify_problem_form").submit(function(e){
		//verify input
		var data = new FormData($('#modify_problem_form')[0]);
		
		$.ajax({
			'type':'POST',
			'url':'manageProblem.pl',
			'async':true,
			'cache': false,
			'processData': false,
			'contentType':'multipart/form-data',
			'success':function(a){
				$("#modifyProblemErrorMessage").hide();
				if(a.status == 0){ //failure
					$("#modifyProblemErrorMessage").text(a.message).show();
				}else{
					$("#modifyProblemErrorMessage").hide().text("");
					
					$('#modify_problem').dialog('close');
					$("#modify_problem_form")[0].reset();
					
					//add row to table
					var row = $('#problem_head_' + a.problem.p_id);
					$('div.problemname', row).html(a.problem.problemname);

				}
			},
			'complete':function(a){
				//$(".c_loading").hide();
			},
			'error':function(xhr, ajaxOptions, error){
				$("#modifyProblemErrorMessage").text("Error communicating with server.");
				$("#modifyProblemErrorMessage").show();
			},
			'data': data
		});

		return false;	
	});
	
});

