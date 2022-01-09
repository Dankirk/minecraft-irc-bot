/*
	Handles Rule view of MC AutoReply at http://sasami.no-ip.org/minecraft/index.php
	
	by Dankirk 2012 | #fcraft@EsperNet
*/
function delRow(tableID, i) {
	var table = document.getElementById(tableID);
	if (table == null) 
		return;
	
	// don't delete the header row (id 0)
	if ((i >= 1 && i < table.rows.length) || (i == -1 && table.rows.length > 1)) {
		table.deleteRow(i);
		
		// Decrement parameter for delRow() for rows after the one we just deleted
		if (i != -1) {
			for (;i < table.rows.length;i++) {
				
				document.getElementByName("rule_enabled["+i+"]").setAttribute("name", "rule_enabled["+(i-1)+"]");
				document.getElementByName("rule_match["+i+"]").setAttribute("name", "rule_match["+(i-1)+"]");
				document.getElementByName("rule_reply["+i+"]").setAttribute("name", "rule_reply["+(i-1)+"]");
				table.rows[i].cells[3].innerHTML = "<img src=\"del.png\" onclick=\"delRow('"+table.getAttribute("id") +"',"+ i +")\" />";
		
			}
		}		
	}
}

// Adds new rank entry to table
function addRow(tableID) {

	var table = document.getElementById(tableID);
	if (table == null) 
		return;
			
	if (table.rows.length > 40)
		return;
	
	var row = table.insertRow(-1);
	if (row) {
		var rowID = table.rows.length -2;

		var cell = row.insertCell(-1);
		cell.innerHTML = "<p align=center><input type='checkbox' name='rule_enabled["+rowID+"]' checked=checked value='1' height='10' /></p>";

		cell = row.insertCell(-1);
		cell.innerHTML = "<input type='text' size=64 maxlength=256 name='rule_match["+rowID+"]' value='' />";

		cell = row.insertCell(-1);
		cell.innerHTML = "<input type='text' size=64 maxlength=128 name='rule_reply["+rowID+"]' value='' />";
		
		cell = row.insertCell(-1);
		cell.innerHTML = "<img src=\"del.png\" onclick=\"delRow('"+table.getAttribute("id") +"',"+(rowID+1)+")\" >";
	}
}