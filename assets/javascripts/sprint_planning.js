function init_planning(){
	$j('.sprint-info').click(function() {
		$(this).next().toggle('slow');
		return true;
	}).next().hide();

	$j('.sprint-info')[0].next().show('slow');
	
	init_sortable();
}

function update_sprint_status(){
	$j('.sprint').each(function(){
	var size = 0;
	var cf_1 = $j('.autoscroll > table > tbody > tr.issue .cf_1', this);
	$j('span , div',cf_1).each(function(){
		size += parseInt($j(this).html());
	});
	var buffer_size = parseInt($j(this).prev().attr('buffer-size'))
	var status = Math.round((size / buffer_size) * 1000) / 10;
	var statusHTML = "" + size + "/" + buffer_size;
	
	$j('.status-bar', $j(this).prev()).progressbar({value:  status});
	$j('.size', $j(this).prev()).html(statusHTML);
	});
}

function init_sortable(){
	$j('tbody').sortable({
		revert: true,
		appendTo: 'body',
		tolerance: 'pointer',
		items: '.issue',
		connectWith: $j('tbody'),
		update: function(event, ui){
			// get the dragged row id (e.g. 'issue-5')
			var id = ui.item[0].id;
			
			$j(ui.item).after($j('#placeholder-'+id.replace('issue-','')));
				
			var index = ui.item.index();
			
			// update row actions to fit the new table.
			var list_id = $j(ui.item)[0].parentNode.parentNode.parentNode.parentNode.id;
			$j('.issue-actions > a', $j('#'+id)).each(function(){
				var request = $j(this).attr('onclick');
				request = request.replace(/list_id=[^\']*/,"list_id="+list_id);
				$j(this).attr('onclick',request);
			});
			
			// alert ('ajax req'+value);
			// // changing the fixed-version of the issue ussing AJAX request
			// new Ajax.Request(url,{
				// parameters:{
					// id: id +"-version",
					// index: index,
					// value:list_id
					// },
				// method: 'post',
					// asynchronous:true
				// });
		}
	});
		
}
