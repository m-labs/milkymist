ncoef = 128;

amp = 32768;
fs = 48000;
f1 = 150/fs;
f2 = 600/fs;
f3 = 2900/fs;

fid = mopen("bandfilters.h", "w");
if (fid == -1)
	error("cannot open file for writing");
end

mfprintf(fid, "/* Generated automatically by bandfilters.sce. Do not edit manually. */\n\n");

mfprintf(fid, "const static int bass_filter[%d] = {\n", ncoef);
bass = ffilt("lp", ncoef, f1);
for i=1:ncoef
	mfprintf(fid, "%d,\n", amp*bass(i));
end
mfprintf(fid, "};\n\n");

mfprintf(fid, "const static int mid_filter[%d] = {\n", ncoef);
mid = ffilt("bp", ncoef, f1, f2);
for i=1:ncoef
	mfprintf(fid, "%d,\n", amp*mid(i));
end
mfprintf(fid, "};\n\n");

mfprintf(fid, "const static int treb_filter[%d] = {\n", ncoef);
treb = ffilt("bp", ncoef, f2, f3);
for i=1:ncoef
	mfprintf(fid, "%d,\n", amp*treb(i));
end
mfprintf(fid, "};\n\n");

mclose(fid);

// To plot :
//
//[hm,fr] = frmag(bass, 256);
//plot2d(fr',hm');
//[hm,fr] = frmag(mid, 256);
//plot2d(fr',hm');
//[hm,fr] = frmag(treb, 256);
//plot2d(fr',hm');

quit
