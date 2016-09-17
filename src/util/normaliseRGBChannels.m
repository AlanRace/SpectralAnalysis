% Normalise RGB channels individually to their min/max values
function normalised = normaliseRGBChannels(rgb)

normalised = (rgb(:, :, 1) - min(min(rgb(:, :, 1)))) ./ (max(max(rgb(:, :, 1))) - min(min(rgb(:, :, 1))));
normalised(:, :, 2) = (rgb(:, :, 2) - min(min(rgb(:, :, 2)))) ./ (max(max(rgb(:, :, 2))) - min(min(rgb(:, :, 2))));
normalised(:, :, 3) = (rgb(:, :, 3) - min(min(rgb(:, :, 3)))) ./ (max(max(rgb(:, :, 3))) - min(min(rgb(:, :, 3))));
