_G["BINDING_NAME_CLICK RotatingMarker:LeftButton"] = "Rotating Marker"
_G["BINDING_NAME_CLICK RotatingMarker:0"] = REMOVE_WORLD_MARKERS
for i = 1, 8 do
    _G["BINDING_NAME_CLICK RotatingMarker:"..i] = _G["WORLD_MARKER"..i]
end
