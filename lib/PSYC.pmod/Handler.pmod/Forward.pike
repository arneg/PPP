inherit PSYC.Handler.Base;

constant _ = ([
    "postfilter" : ([
	"" : 0
    ])
]);

int postfilter(MMP.Packet p, mapping _v) {
    call_out(uni->distribute, 0 ,p);
    return PSYC.Handler.GOON;
}
