function split = strsplit(str, pattern)

strings = java.lang.String(d).split(pattern);

split = {};

for i = 1:strings.length()
    split{i} = strings(i);
end