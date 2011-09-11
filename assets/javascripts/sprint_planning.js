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
			size += parseInt($j(this).html());
		});
		var buffer_size = parseInt($j(this).prev().attr('buffer-size'))
		var status = Math.round((size / buffer_size) * 1000) / 10;
		var statusHTML = "" + size + "/" + buffer_size;

		$j('.status-bar', $j(this).prev()).progressbar({
			value:  status
		});
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
				request = request.replace(/list_id=[^\']*/,"list_id="+list_id);
				$j(this).attr('onclick',request);
			});
			// dividing by two, because each issue take 2 rows (issue & placeholder)
			var index = ui.item.index() / 2;

			// changing the fixed-version of the issue ussing AJAX request
			new Ajax.Request(url, {
				parameters: {
					id: id +"-version",
					index: index,
					value:list_id
				},
				method: 'post',
				asynchronous:true
			});
		}
	});

}