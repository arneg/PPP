// vim:syntax=lpc
constant String 	= 1 << __LINE__;
constant Integer 	= 1 << __LINE__;
constant Uniform 	= 1 << __LINE__;
constant BEGIN_MODIFIERS = (1 << __LINE__) - 1;
constant Sentence 	= 1 << __LINE__;
constant Place 		= 1 << __LINE__;
constant User 		= 1 << __LINE__;
// ^^ no comments here! there will be dragons

mapping _ = ([ ]);

mixed parse(int type, array(string) data, object ui) {
    switch(type & BEGIN_MODIFIERS) {
    case String:
	if (type & Sentence) {
	    return ({ sizeof(data), data * " " });
	}

	return ({ 1, data[0] });
    case Integer:
	if ((string)((int)data[0]) == data[0]) {
	    return ({ 1, (int)data[0] });
	}

	return ({ 0, "It's not an Integer, baby." });
    case Uniform:
	{
	    MMP.Uniform u;

	    if (type & Place) {
		u = ui->client->room_to_uniform(data[0]);
	    } else {
		u = ui->client->user_to_uniform(data[0]);	
	    }

	    if (u) {
		return ({ 1, u });
	    }

	    return ({ 0, "Exceeds my definition of Uniforms by years "
		         "of science!" });
	}
    }
}

