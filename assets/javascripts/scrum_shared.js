function toggleScrumRowGroup(el) {
	var tr = Element.up(el,
		 'tr');
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

function cancelInlineChild(elem){
	$j(elem).parents('.inline_child_container').each(function(index, element){
		element.innerHTML = '';
	});
}

ContextMenu.prototype.showMenu = function(e) {
  var mouse_x = Event.pointerX(e);
  var mouse_y = Event.pointerY(e);
  var render_x = mouse_x;
  var render_y = mouse_y;
  var dims;
  var menu_width;
  var menu_height;
  var window_width;
  var window_height;
  var max_width;
  var max_height;

  $('context-menu').style['left'] = (render_x + 'px');
  $('context-menu').style['top'] = (render_y + 'px');     
  Element.update('context-menu', '');
  
  // collect ids
  ids_params_string = '';
  selected_id = $j('#issue-table input[name="ids[]"]').each(
									function(index, element){
										if(element.checked)
											ids_params_string += 'ids[]=' + element.value + '&';
									});

  new Ajax.Updater({success:'context-menu'}, this.url, 
    {asynchronous:true,
     method: 'get',
     evalScripts:true,
     parameters: ids_params_string + Form.serialize($('context_menu_form')),
     onComplete:function(request){
               dims = $('context-menu').getDimensions();
               menu_width = dims.width;
               menu_height = dims.height;
               max_width = mouse_x + 2*menu_width;
               max_height = mouse_y + menu_height;
          
               var ws = window_size();
               window_width = ws.width;
               window_height = ws.height;
          
               /* display the menu above and/or to the left of the click if needed */
               if (max_width > window_width) {
                 render_x -= menu_width;
                 $('context-menu').addClassName('reverse-x');
               } else {
                   $('context-menu').removeClassName('reverse-x');
               }
               if (max_height > window_height) {
                 render_y -= menu_height;
                 $('context-menu').addClassName('reverse-y');
               } else {
                   $('context-menu').removeClassName('reverse-y');
               }
               if (render_x <= 0) render_x = 1;
               if (render_y <= 0) render_y = 1;
               $('context-menu').style['left'] = (render_x + 'px');
               $('context-menu').style['top'] = (render_y + 'px');
               
       Effect.Appear('context-menu', {duration: 0.20});
       if (window.parseStylesheets) { window.parseStylesheets(); } // IE
    }});
}

function clear_form_elements(ele) {
    $j(ele).find(':input').each(function() {
        switch(this.type) {
            case 'password':
            case 'select-multiple':
            case 'select-one':
            case 'text':
            case 'textarea':
                value = typeof(default_issue_description) == "undefined" ? "" : default_issue_description;
                $j(this).val(value);
                break;
            case 'checkbox':
            case 'radio':
                this.checked = false;
        }
    });

}
