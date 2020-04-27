import util.AssetPaths;
import util.Reg;
import Types;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxObject.*;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import openfl.Assets;

import zero.utilities.IntPoint;
import zero.flixel.input.PlayerController;
import zero.flixel.states.State;
import zero.flixel.utilities.GameLog;
import zero.flixel.utilities.GameSave;

using Math;
using Std;

using zero.extensions.ArrayExt;
using zero.extensions.FloatExt;
using zero.extensions.StringExt;
using zero.flixel.extensions.FlxObjectExt;
using zero.flixel.extensions.FlxPointExt;
using zero.flixel.extensions.FlxSpriteExt;
using zero.flixel.extensions.FlxTilemapExt;
