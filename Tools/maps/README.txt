Background maps for AutoMarkerEditor.html
==========================================

The PNG files here were converted from the .blp images of the Maps folder (Atlas) and are listed in index.js
(image names, and the Map.dbc ids they belong to). The page picks the right image by itself when you select a
map (by id first, then by the map name recorded in AutoMarker_Config.txt); use the list under "Background image"
to choose another one, for example another wing of Dire Maul or Scarlet Monastery.

Calibration (once per image): select the map, click "Calibrate", click a recognisable spot on the image, then click
the mob that stands there; do it twice with two spots far from each other. The result is kept in your browser.
"Export calibrations..." writes calibration.js: put that file in this folder and the calibrations travel with the
maps (other browsers, other computers).

To add an image: save it here as <Name>.png and add <Name> to the AM_IMAGES list of index.js (or load it with the
"Load image..." button, which keeps it in your browser only). Browsers cannot display .blp or .tga files.
