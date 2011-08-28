function init_drag_and_drop(){
	$j('tr.issue').draggable({
		helper: 'clone',
		revert: 'invalid',
		appendTo: 'body',
		drag: function(){
				$j(this).hide('slow');
		},
		stop: function(){
				$j(this).show('slow');
				
				// update the status of each sprint
				update_sprint_status();
			}
	});
	
	$j('.sprint , #backlog').droppable({
		drop: function(){
			// get the dragged row id (e.g. 'issue-5')
			var  id = $j('.ui-draggable-dragging')[0].id;
			
			// prevent sending request if the issue dropped in the same place
			if ($j('.autoscroll > table > tbody > tr#'+id,this).size() != 0)
				return;
			
			// append the row and the inline-place-holder to the new table
			var tr = $j('#'+id+' + tr');
			$j('.autoscroll > table > tbody',this).append($j('#'+id));
			$j('.autoscroll > table > tbody',this).append(tr);
			
			// update row actions to fit the new table.
			var list_id = $j(this)[0].id.toString();
			$j('.issue-actions > a', $j('#'+id)).each(function(){
				var request = $j(this).attr('onclick');
				request = request.replace(/list_id=[^\']*/,"list_id="+list_id);
				$j(this).attr('onclick',request);
			});
			
			// changing the fixed-version of the issue ussing AJAX request
			new Ajax.Request(url,{
				parameters:{
					id: id +"-version",
					value:this.id
					},
				method: 'post',
					asynchronous:true
				});
			}
			
		});
}
	
function init_planning(){
	$j('.sprint-info').click(function() {
	$(this).next().toggle('slow');
	return true;
}).next().hide();

$j('.sprint-info')[0].next().show('slow');
	
	init_drag_and_drop();
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