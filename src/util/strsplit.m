function split = strsplit(str, pattern)

strings = java.lang.String(str).split(pattern);

split = {};

for i = 1:strings.length()
    split{i} = strings(i);
end