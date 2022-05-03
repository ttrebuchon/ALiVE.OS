#include "\x\alive\addons\x_lib\script_component.hpp"
SCRIPT(binPacking);

/* ----------------------------------------------------------------------------
Function: ALiVE_fnc_binPacking
Description:
TODO
Parameters:
    GroupDatas - Array of size datas [size, data]
    BinDatas - Array of container size datas [size, data]
    BestFit - Whether to attempt to find a best fit or to exit early if impossible (Boolean)
    
Returns:
    Success - Boolean indicating whether calculation was successful
    Array of pairs;
        GroupData
        BinData
Examples:
(begin example)
private _groups = [
    [2, "A"],
    [1, "B"],
    [1, "C"],
    [4, "X"]
];
private _containers = [
    [6, 10],
    [1, "1"],
    [2, "D"]
];

private _solution = [_groups, _containers, true] call ALiVE_fnc_binPacking;
// Potential contents of _solution:
//[true,
//    [
//        [10, ["A", "X"]],
//        ["D", ["B", "C"]]
//    ]
//]
(end)
Author:
TTreb
---------------------------------------------------------------------------- */


params [
	"_items",
	"_bins",
	["_bestFit", false, [false]]
];

private ["_result", "_success", "_emptyItems", "_fullPairs", "_totalItemSize", "_totalBinSize", "_tmp"];

_emptyItems = [];



// Sort bins and filter out the ones with
// no capacity
_bins = [_bins, [], { _x select 0 }, "DESCEND", { _x select 0 > 0}] call BIS_fnc_sortBy;


if (count _bins == 0) exitWith {
	[false, []];
};

_tmp = _items;
_items = [];


{
	if (_x select 0 > 0) then {
		_items pushBack _x;
	} else {
		_emptyItems pushBack _x;
	};
} forEach _tmp;



_totalItemSize = 0;
_totalBinSize = 0;
{
	_totalItemSize = _totalItemSize + (_x select 0);
} forEach _items;

{
	_totalBinSize = _totalBinSize + (_x select 0);
} forEach _bins;


// If we know for a fact that we can't fit all of the items in 
// and we aren't looking for a best fit then we can exit with 
// failure now.
if (!_bestFit && _totalItemSize > _totalBinSize) exitWith {
	[false, []];
};


_items = [_items, [], { _x select 0 }, "DESCEND"] call BIS_fnc_sortBy;


private ["_success", "_binData", "_stranded", "_matched", "_item"];

_success = true;
_binData = _bins apply { [_x select 0, _x select 0, [], _x select 1] };
_stranded = [];

scopeName "binPacking";
{
	_matched = false;
	_item = _x;
	{
		if ((_item select 0) <= (_x select 1)) exitWith {
			(_x select 2) pushBack _item;
			_x set [1, (_x select 1) - (_item select 0)];
			_matched = true;
		};
	}
	forEach _binData;
	
	if (!_matched) then {
		_success = false;
		if (!_bestFit) then {
			breakTo "binPacking";
		} else {
			_stranded pushBack _item;
		};
	} else {
	
		_binData = [_binData, [], { (_x select 1) + (if ((_x select 1) < (_x select 0)) then { 1000 } else { 0 }) }, "DESCEND"] call BIS_fnc_sortBy;
		
	};
	
	
	
} forEach _items;

if (!_success && !_bestFit) exitWith {
	[false, []];
};

// TODO: Cleanup/rearrange for more optimal usage
// of bins


// Re-add those empty items which don't impact anything
{
	(_binData select 0) select 2 pushBack _x;
} forEach _emptyItems;

// Format the results
_result = [];
{
	if (count (_x select 2) > 0) then {
		_result pushBack [_x select 3, (_x select 2) apply { _x select 1 }];
	};
} forEach _binData;




[_success, _result];