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
var Table = function() { 
	this.rows = new Mapping();
	this.columns = new Mapping();
};
Table.prototype = {
	getRow : function(id) {
		return this.rows.get(id);
	},
	getColumn : function(id) {
		return this.columns.get(id);
	},
	sortRows : function(compare) {
		//P("rows: "+this.getRows());
		var nlist = this.getRows();

		if (compare) {
			nlist.sort(compare);
		} else {
			nlist.sort();
		}

		// when nlist[i] has been swapped, its at the correct place. so dont touch it again
		for (var i = 0; i < nlist.length; i++) {
			var current = this.getRowByPos(i);
			if (current != nlist[i]) {
				this.switchRows(current, nlist[i]);
			}
		}
	},
	sortColumns : function(list) {
	},
	addRow : function(id, row) {
		if (this.rows.hasIndex(id)) {
			throw("overwriting row, probably by mistake. delete first.");
		}
		this.rows.set(id, row);
	},
	deleteRow : function(id) {
		this.rows.remove(id);
	},
	addColumn : function(id, column) {
		if (this.columns.hasIndex(id)) {
			throw("overwriting column, probably by mistake. delete first.");
		}
		this.columns.set(id, column);
	},
	deleteColumn : function(id) {
		this.columns.remove(id);
	},
	switchColumns : function(column1, column2) { },
	switchRows : function(row1, row2) { }
};
var TypedTable = function(list) {
	Table.call(this);
	this.addRow = function(id) {
		var node = document.createElement("tr");
		node.id = id.toString();
		this.columns.forEach((function (key, value) {
			node.appendChild(document.createElement("td"));
		}));

		this.tbody.appendChild(node);
		TypedTable.prototype.addRow.call(this, id, node);
	};
	this.deleteRow = function(id) {
		var node = this.getRow(id);
		this.tbody.removeChild(node);
		TypedTable.prototype.deleteRow.call(this, id);
	};
	this.sortRows = function(compare) {
		// DONT edit DOM thats in the tree and
		// will be rerendered
		this.table.removeChild(this.thead);
		this.table.removeChild(this.tbody);
		TypedTable.prototype.sortRows.call(this, compare);
		this.table.appendChild(this.thead);
		this.table.appendChild(this.tbody);
	};
	this.render = function(o) {
		if (typeof(o) == "object") {
			return o;
		}

		return document.createTextNode(o.toString());
	};
	this.addColumn = function(id, head) {
		TypedTable.prototype.addColumn.call(this, id, this.num_columns++);	

		this.rows.forEach((function(key, value) {
			value.appendChild(document.createElement("td"));
		}));

		var th = document.createElement("th");
		if (head) {
			th.appendChild(this.render(head));
		}
		this.table.tHead.rows[0].appendChild(th);
	};
	this.getHead = function(column) {
		var num = this.getColumn(column);
		return this.table.tHead.rows[0].childNodes[num];
	};
	this.addCell = function(row, column, o) {
		var row = this.getRow(row);
		var num = this.getColumn(column);
		var cell = row.childNodes[num];
		var node = this.render(o);
	if (cell.hasChildNodes()) {
			cell.replaceChild(node, cell.firstChild);
		} else {
			cell.appendChild(node);
		}
		return cell;
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
		var ret = new Array();
		for (var i = 0; i < this.tbody.childNodes.length; i++) {
			ret.push(this.tbody.childNodes[i]);
		}
		return ret;
		return Array.prototype.slice.call(this.tbody.childNodes);
	};
	this.sortByColumn = function(name, cmp) {
		var num = this.getColumn(name);
		var compare = function(a, b) {
			return cmp(a.childNodes[num], b.childNodes[num]);
		}
		this.sortRows(compare);
	}

	this.num_columns = 0;
	this.table = document.createElement("table");

	this.thead = document.createElement("thead");
	this.thead.appendChild(document.createElement("tr"));
	this.table.appendChild(this.thead);
	this.tbody = document.createElement("tbody");
	this.table.appendChild(this.tbody);

/*
	if (list) {
		for (var i = 0; i < list[0].length; i++) {
			this.addColumn(list[0][i]);	
		}
		
		for (var i = 1; i < list.length; i++) {
			this.addRow(list[i]["column1"]);
			for (var j = 0; j < list[0].length; j++) {
				this.addCell(list[i]["column1"], list[0][j], list[i][list[0][j]]);
			}
		}
	}
*/
};
TypedTable.prototype = new Table();
TypedTable.prototype.constructor = TypedTable;
