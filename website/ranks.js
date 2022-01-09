/*
	Handles Rank view of MC AutoReply at http://sasami.no-ip.org/minecraft/index.php
	
	by Dankirk 2012 | #fcraft@EsperNet
*/

// Sets Preview field value for all rank entries according to selected colors and typed prefixes
function setExample() {		
	
	var form = document.getElementById("rank_form");
	if (form == null) return;

	var colors = form.elements["rank_color[]"];	
	var prefixes = form.elements["rank_prefix[]"];	
	var examples = form.elements["rank_example[]"];
	
	if (colors != null && prefixes != null && examples != null) {	
	
		// For some magic javascript reason .length is undefined if array contains only 1 element
		// To circumvent this: add 1 tablerow, re-get array reference (now magically with valid .length), and then remove the temporary row we just added
		if (!colors.length || !prefixes.length || !examples.length) {
			addRow('RankTable',1);
			colors = form.elements["rank_color[]"];	
			prefixes = form.elements["rank_prefix[]"];	
			examples = form.elements["rank_example[]"];
			delRow(-1);
			
			if (!colors.length || !prefixes.length || !examples.length)
				return;
		}
		
		var len = colors.length;		
		if (len == prefixes.length && len == examples.length) {	
			for (var i = 0; i < len; i++) {			
				examples[i].value = prefixes[i].value + "Dankirk";
				examples[i].style.color=mIRCtoHex(colors[i].value);
			}	
		}	
	}
}

// Transforms mIRC color codes to hex
function mIRCtoHex(i) {
	if (i == 0) return "#FFFFFF";
	if (i == 1) return "#000000";
	if (i == 2) return "#00007F";
	if (i == 3) return "#009300";
	if (i == 4) return "#FF0000";
	if (i == 5) return "#7F0000";
	if (i == 6) return "#9C009C";
	if (i == 7) return "#FC7F00";
	if (i == 8) return "#FFFF00";
	if (i == 9) return "#00FC00";
	if (i == 10) return "#009393";
	if (i == 11) return "#00FFFF";
	if (i == 12) return "#0000FC";
	if (i == 13) return "#FF00FF";
	if (i == 14) return "#7F7F7F";
	if (i == 15) return "#D2D2D2";
	return "#FFFFFF";
}	

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
				table.rows[i].cells[6].innerHTML = "<img src=\"del.png\" onclick=\"delRow('"+table.getAttribute("id") +"',"+ i +")\" />";
			}
		}		
	}
}

// Adds new rank entry to table, if se=1 Preview will NOT be set
function addRow(tableID, se) {

	var table = document.getElementById(tableID);
	if (table == null)
		return;
			
	if (table.rows.length > 20)
		return;
		
	if (!se)
		var se = 0;
	
	var row = table.insertRow(-1);

	var cell = row.insertCell(-1);
	cell.innerHTML = "<input type='text' size=16 maxlength=16 name='rank_title[]' value='New Rank' />";

	cell = row.insertCell(-1);
	cell.innerHTML = "<input type='text' size=2 maxlength=2 name='rank_val[]' value=" + (table.rows.length-2) + " />";

	cell = row.insertCell(-1);
	cell.innerHTML = "<input type='text' size=2 maxlength=1 name='rank_prefix[]' onkeyup='setExample()' />";
	
	cell = row.insertCell(-1);
	var combo = document.createElement('select');
	combo.setAttribute('name','rank_color[]');
	combo.setAttribute('onchange','setExample()');
	
	var opt = combo.appendChild(document.createElement('option'));	
	opt.value=0; opt.text="white";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=1; opt.text="black"; opt.setAttribute('selected','selected');
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=2; opt.text="navy (blue)";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=3; opt.text="green";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=4; opt.text="red";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=5; opt.text="maroon (red)";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=6; opt.text="purple";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=7; opt.text="olive";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=8; opt.text="yellow";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=9; opt.text="lime";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=10; opt.text="teal";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=11; opt.text="aqua";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=12; opt.text="blue";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=13; opt.text="magenta (pink)";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=14; opt.text="grey";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=15; opt.text="silver";
	
	cell.appendChild(combo);	

	cell = row.insertCell(-1);
	combo = document.createElement('select');
	combo.setAttribute('name','rank_promoto[]');
	
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=0; opt.text="None";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=1; opt.text="Build good";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=2; opt.text="Apply at website";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=3; opt.text="Automatic/Stats";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=4; opt.text="Manual/Stats";
	opt = combo.appendChild(document.createElement('option'));	
	opt.value=5; opt.text="Donate";
	
	cell.appendChild(combo);

	cell = row.insertCell(-1);
	cell.innerHTML = "<input type='text' size=8 maxlength=18 id='rank_example[]' readonly='readonly' />";
	
	cell = row.insertCell(-1);
	cell.innerHTML = "<img src=\"del.png\" onclick=\"delRow('"+table.getAttribute("id") +"',"+ (table.rows.length -1) +")\" />";
	
	if (se == 0)
		setExample();

}