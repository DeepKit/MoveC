.mode column
.headers on
SELECT image_key, length(image_data) as size, address_text FROM donation_images ORDER BY image_key;
