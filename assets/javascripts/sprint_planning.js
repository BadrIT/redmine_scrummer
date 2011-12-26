function init_planning() {
	$j('.sprint-info').click( function() {
		$(this).next().toggle('slow');
		return true;
	}).next().hide();
	$j('.sprint-info')[0].next().show('slow');

	init_sortable();
}

function update_sprint_status() {
	$j('.sprint').each( function() {
		var size = 0;
		var cf_1 = $j('.autoscroll > table > tbody > tr.issue .cf_1', this);
		$j('span , div',cf_1).each( function() {
			if (!isNaN(parseInt($j(this).html()))){
				size += parseInt($j(this).html());
			}
		});
		var buffer_size = parseInt($j(this).prev().attr('buffer-size'))
		var status = Math.round((size / buffer_size) * 1000) / 10;
		var statusHTML = "" + size + "/" + buffer_size;
		if (size > 0) {
			$j('.status-bar', $j(this).prev()).progressbar({
				value: status
			});
		}
		$j('.size', $j(this).prev()).html(statusHTML);
	});
}

/*
 This function moves each inline place holder to the correct place because drag and drop
 may put it in inccorect place
 * */
function correct_placeholders_positions(tbody) {
	$j('tr.issue', tbody).each( function() {
		var id = $j(this)[0].id.replace('issue-','');
		$j(this).after($j('#placeholder-'+id));
	});

	if($j(tbody).find("tr").length > 0){
		$j(tbody).find("#empty_issues").remove();
	}
	fix_sprints(); // adding the "No issues in this sprint" row for the empty sprints
}

function fix_sprints(){
	$j(".ui-sortable").each(function() {
		if($j(this).find("tr").length == 0){
			$j(this).append("<td height='30' colspan='20' align='center'><b>No issues in this sprint</b></td>");
		}
	});	
}

function init_sortable() {
	$j('tbody').sortable({
		revert: true,
		appendTo: 'body',
		tolerance: 'pointer',
		items: '.issue',
		connectWith: $j('tbody'),
		dropOnEmpty: true,
		update: function(event, ui) {
			// preventing firing 'update' twice
			// http://forum.jquery.com/topic/sortables-update-callback-and-connectwith
			if (this != ui.item.parent()[0])
				return;

			// get the dragged row id (e.g. 'issue-5')
			var id = ui.item[0].id;

			// if issues aren't sorted by rank, move the dragged issue dwon
			if ($j(this).attr('sort') != 'position') {
				$j(this).append($j(ui.item)[0]).fadeIn();
			}

			// check for any placeholders positions errors
			correct_placeholders_positions(this);
			
			// update row actions to fit the new table.
			var list_id = $j(ui.item)[0].parentNode.parentNode.parentNode.parentNode.id;
			$j('.issue-actions > a', $j('#'+id)).each( function() {
				var request = $j(this).attr('onclick');
				request = request.replace(/from_sprint=[^\']*&list_id=[^\']*/, "from_sprint=" + list_id +"&list_id=" + list_id);
				$j(this).attr('onclick',request);
			});
			// dividing by two, because each issue take 2 rows (issue & placeholder)
			var index = ui.item.index() / 2;
			
			// changing the fixed-version of the issue ussing AJAX request
			new Ajax.Request(url, {
				parameters: {
					id: id +"-version",
					index: index,
					value:list_id,
					first_index: $$("#first_index").first().value
				},
				onSuccess: function(){
					$$("#position-" + id).first().value = index;
					$$("#first_index").first().value = index;
			    },
				method: 'post',
				asynchronous:true
			});
		}
	});
}