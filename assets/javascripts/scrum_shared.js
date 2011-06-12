$j(function(){
	alert.hi();
});

function addInLineChild(elem){
	row = $j(elem).closest('tr')[0];
	
	issueId = row.id.replace('issue-', '');
	issueId = parseInt(issueId);
	
	if( $j('#new_issue_inline_add_child_for_elem_' + row.id).length > 0 )
		return;
	
	// clone template
	template = $('new_issue_inline_div');
	inlineForm = template.cloneNode();
	inlineForm.id = 'new_issue_inline_add_child_for_elem_' + row.id;
	inlineForm.innerHTML = template.innerHTML;
	
	$j(inlineForm).removeClass('add_inline_child_template');
	$j(inlineForm).addClass('add_inline_child');
	
	// add it next to the current row
	nextRow = row.next();
	
	newRow = createTableRowWithContent(nextRow, inlineForm);
	tableBody = $j(nextRow).closest('tbody')[0];
	
	tableBody.insertBefore(newRow, nextRow);		
	
	$j(inlineForm).slideDown('slow');
	
	// set the row id
	$j(inlineForm).find('#issue_parent_issue_id').attr('value', issueId)
}

function createTableRowWithContent(sampleTr, content){
	row = document.createElement('tr');
	td = document.createElement('td');
	
	colSpan = $j(sampleTr).find('td').length;
	td.colSpan = colSpan;
	
	td.appendChild(content);
	
	row.appendChild(td);
	
	return row;
}

function toggleScrumRowGroup(el) {
	var tr = Element.up(el, 'tr');
	var n = Element.next(tr);
	tr.toggleClassName('open');
	var isOpened = $j(tr).hasClass('open')
	
	trLevel = parseInt($j(tr).attr('level'));
	nLevel = trLevel + 1;
	
	while (n != undefined && nLevel > trLevel) {
		if(isOpened){			
			$j(n).show();
			if($j(n).hasClass('group'))
				$j(n).addClass('open')
		} else {
			$j(n).hide();
			if($j(n).hasClass('group'))
				$j(n).removeClass('open')
		}
		
		n = Element.next(n);
		nLevel = parseInt($j(n).attr('level'));
		
	}
}