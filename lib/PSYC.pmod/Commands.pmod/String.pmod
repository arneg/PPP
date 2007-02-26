array parse(string data, object ui, int|void length) {
    if (!length) {
	return ({ sizeof(data), data });
    }

    if (sizeof(data) < length) return ({ 0, "Input too short." });

    return ({ length, data[0 .. length-1] });
}
