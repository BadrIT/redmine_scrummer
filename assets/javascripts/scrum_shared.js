
function addInLineChild(elem){
	row = $j(elem).closest('tr')[0];
	
	issueId = row.id.replace('issue-', '');
	issueId = parseInt(issueId);
	
	if( $j('#new_issue_inline_add_child_for_elem_' + row.id).length > 0 )
		return;
	
	// clone template
	container = document.createElement('div')
	container.id = 'inline_add_container-issue-' + issueId;
	
	template = $('new_issue_inline_div');
	inlineForm = template.cloneNode();
	container.appendChild(inlineForm);
	
	inlineForm.id = 'new_issue_inline_add_child_for_elem_' + row.id;
	inlineForm.innerHTML = template.innerHTML;
	
	$j(inlineForm).removeClass('add_inline_child_template');
	$j(inlineForm).addClass('add_inline_child');
	
	// add it next to the current row
	nextRow = row.next();
	
	newRow = createTableRowWithContent(nextRow, container);
	tableBody = $j(nextRow).closest('tbody')[0];
	
	tableBody.insertBefore(newRow, nextRow);		
	
	$j(inlineForm).slideDown('slow');
	
	// set the row id
	$j(inlineForm).find('#issue_parent_issue_id').attr('value', issueId);
	
	// observe changes of tracker field
	observeTrackerField( container, inlineForm, issueId );
}

function observeTrackerField(container, form, issueId){
	containerId = container.id;
	form = $j(form).find('form')[0];
	field = $j(form).find('[name="issue[tracker_id]"]')[0];
	
	observeFor(field, form, containerId);
}

function observeFor(field, form, containerId){
	new Form.Element.EventObserver(field,
																function(element, value) {
																	new Ajax.Updater(containerId, 
																					 tracker_id_observer_url, 
																					 {
																						 asynchronous: true, 
																						 evalScripts: true, 
																						 parameters: form.serialize()																									 
																					 }
																	)
																});
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