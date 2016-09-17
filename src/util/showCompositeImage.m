function showCompositeImage(image1, image2, image3)

if(nargin < 3)
    image3 = image1;
end

composite = (image1.imageData - min(image1.imageData(:))) ./ (max(image1.imageData(:)) - min(image1.imageData(:)));
composite(:, :, 2) = (image2.imageData - min(image2.imageData(:))) ./ (max(image2.imageData(:)) - min(image2.imageData(:)));
composite(:, :, 3) = (image3.imageData - min(image3.imageData(:))) ./ (max(image3.imageData(:)) - min(image3.imageData(:)));

figure, imagesc(composite);
axis image; axis off;