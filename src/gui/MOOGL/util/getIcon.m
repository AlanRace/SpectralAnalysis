function icon = getIcon(name, backgroundColour, iconColour)

iconFolder = [fileparts(mfilename('fullpath')) filesep '..' filesep 'icons'];

[~, ~, transparency] = imread([iconFolder filesep name '-24px.png']);

transparency = double(transparency) ./ 255;

r = (1 - transparency) .* backgroundColour(1) + transparency .* iconColour(1);
g = (1 - transparency) .* backgroundColour(2) + transparency .* iconColour(2);
b = (1 - transparency) .* backgroundColour(3) + transparency .* iconColour(3);

icon = cat(3, r, g, b);