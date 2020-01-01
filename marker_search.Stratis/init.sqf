["init"] execVM "fnc\fn_markersearch.sqf";
/*
//--- Testing:
_classes = "gettext (_x >> 'markerclass') == 'Military'" configClasses (configFile >> "CfgMarkers");
_classes = _classes apply {configname _x};
for "_i" from 0 to 100 do {
	_pos = [] call BIS_fnc_randomPos;
	_mrk = createMarker [format ["mrk_%1",_i], _pos];
	_mrk setMarkerShape "ICON";
	_mrk setMarkerType selectRandom _classes;
	_mrk setMarkerText format ["Marker_%1",_i];
};