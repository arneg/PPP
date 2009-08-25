var Table = function() { };
function strcmp(str1, str2) {
	if (str1 == str2) {
		return 0;
	}
	if (str1 > str2) {
		return 1;
	} else {
		return -1;
	}
}
Table.prototype = {
	addCell : function(row, column, node) {
		node.row = row;
		node.column = column;
	},
	getRow : function(id) {
		return this.rows[id];
	},
	getColumn : function(id) {
		return this.columns[id];
	},
	sortRows : function(compare) {
		//P("rows: "+this.getRows());
		var nlist = this.getRows();
		var t1 = new Date();

		if (compare) {
			nlist.sort(compare);
		} else {
			nlist.sort();
		}

		t2 = new Date();

		// when nlist[i] has been swapped, its at the correct place. so dont touch it again
		for (var i = 0; i < nlist.length; i++) {
			var current = this.getRowByPos(i);
			if (current != nlist[i]) {
				this.switchRows(current, nlist[i]);
			}
		}

		t3 = new Date();

		debug.innerHTML = "Sort time: " + (t2 - t1) / 1000 + " seconds. Rearrange time: "+ (t3 - t2)/1000 + " seconds.";
	},
	sortColumns : function(list) {
		var compare = function(column1, column2) {
			var a = this.getRow(column1);
			var b = this.getRow(column2);
			return a.cmp(b);
		};
		var nlist = list.sort(this.columns, compare);
		var permuted = {};
		
		for (var i = 0; i < list.length; i++) {
			if (list[i] != nlist[i]) {
				if (!permuted.hasOwnProperty(list[i]) || !permuted.hasOwnProperty(nlist[i])) {
					this.switchColumns(list[i], nlist[i]);
					permuted[list[i]] = 1;
					permuted[nlist[i]] = 1;
				}
			}
		}
	},
	addRow : function(id, row) {
		if (this.rows[id]) {
			throw("overwriting row, probably by mistake. delete first.");
		}
		this.rows[id] = row;
	},
	deleteRow : function(id) {
		this.rows[id] = undefined;
	},
	addColumn : function(id, column) {
		if (this.columns[id]) {
			throw("overwriting column, probably by mistake. delete first.");
		}
		this.columns[id] = column;
	},
	deleteColumn : function(id) {
		this.columns[id] = undefined;
	},
	switchColumns : function(column1, column2) { },
	switchRows : function(row1, row2) { },
};
var NTable = function(list, div) {
	this.columns = {};
	this.rows = {};
	this.num_columns = 0;
	this.table = document.createElement("table");

	this.thead = document.createElement("thead");
	this.thead.appendChild(document.createElement("tr"));
	this.table.appendChild(this.thead);
	this.tbody = document.createElement("tbody");
	this.table.appendChild(this.tbody);

	this.addRow = function(id) {
		var node = document.createElement("tr");
		node.id = id;
		for (var i in this.columns) {
			node.appendChild(document.createElement("td"));
		}

		this.tbody.appendChild(node);
		NTable.prototype.addRow.call(this, id, node);
	};
	this.sortRows = function(compare) {
		// DONT edit DOM thats in the tree and
		// will be rerendered
		this.table.removeChild(this.tbody);
		NTable.prototype.sortRows.call(this, compare);
		this.table.appendChild(this.tbody);
	};
	this.addColumn = function(id) {
		NTable.prototype.addColumn.call(this, id, this.num_columns++);	

		for (var i in this.rows) {
			var row = this.rows[i];
			row.appendChild(document.createElement("td"));
		}

		var th = document.createElement("th");
		var ntable = this;
		th.appendChild(document.createTextNode(id));
		th.onclick = function(event) {
			ntable.sortByColumn(id, function(a,b) {
				return strcmp(a.firstChild.data, b.firstChild.data);
			});
		};
		this.table.tHead.rows[0].appendChild(th);
	};
	this.addCell = function(row, column, node) {
		var row = this.getRow(row);
		var num = this.getColumn(column);
		var cell = row.childNodes[num];
		cell.appendChild(node);
	};
	this.switchRows = function(row1, row2) {

		if (row1 == row2) return;

		if (row1.rowIndex > row2.rowIndex) {
			var c = row1;
			row1 = row2;
			row2 = c;
		}

		var nextSibling = row1.nextSibling;
		if (nextSibling == row2) {
			nextSibling = row1;
		}
		var parentNode = row2.parentNode;
		parentNode.replaceChild(row1, row2);
		parentNode.insertBefore(row2, nextSibling); 
	};
	this.getRowByPos = function(num) {
		return this.tbody.childNodes[num];
	};
	this.getRows = function() {
		return Array.prototype.slice.call(this.tbody.childNodes);
	};
	this.sortByColumn = function(name, cmp) {
		var num = this.getColumn(name);
		var compare = function(a, b) {
			return cmp(a.childNodes[num], b.childNodes[num]);
		}
		this.sortRows(compare);
	}

	for (var i = 0; i < list[0].length; i++) {
		this.addColumn(list[0][i]);	
	}
	
	for (var i = 1; i < list.length; i++) {
		this.addRow(list[i]["column1"]);
		for (var j = 0; j < list[0].length; j++) {
			var tnode = document.createTextNode(list[i][list[0][j]]);
			this.addCell(list[i]["column1"], list[0][j], tnode);
		}
	}

	div.appendChild(this.table);
};
NTable.prototype = new Table();
