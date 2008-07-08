﻿package com.automatastudios.napkin {	import com.adobe.images.JPGEncoder;	import com.dynamicflash.util.Base64;		import flash.display.Sprite;	import flash.display.Bitmap;    import flash.ui.ContextMenu;    import flash.ui.ContextMenuItem;    import flash.ui.ContextMenuBuiltInItems;	import flash.ui.Mouse;	import flash.display.StageAlign;	import flash.display.StageScaleMode;	import flash.events.*;	import flash.net.URLLoader;	import flash.net.URLRequest;	import flash.net.URLRequestMethod;    import flash.net.URLVariables;	import flash.external.ExternalInterface;	import flash.display.BitmapData;	import flash.display.BlendMode;	import flash.utils.ByteArray;		public class Napkin extends Sprite {		private static const IMAGE_QUALITY:uint = 80;		private const DRAW_MODE:String = "draw_mode";		private const ERASE_MODE:String = "erase_mode";				private var _jpgEncoder:JPGEncoder;		private var _menu:ContextMenu;		private var _maxX:Number;	 	private var _maxY:Number;		private var _mode:String;		private var _layers:Array;				private var _canvas:Sprite;		private var _brushes:Sprite;				private var _eraseBrush:EraseBrush;				private var _lastBrush:Sprite;				public function Napkin() {			_canvas = new Sprite();			_canvas.blendMode = BlendMode.LAYER;			addChild(_canvas);						_brushes = new Sprite();			addChild(_brushes);						_eraseBrush = new EraseBrush();			_eraseBrush.blendMode = BlendMode.INVERT;						_layers = new Array();						_jpgEncoder = new JPGEncoder(IMAGE_QUALITY);			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);		}				private function onAddedToStage(evt:Event):void {			stage.scaleMode = StageScaleMode.NO_SCALE;			stage.align = StageAlign.TOP_LEFT;			stage.addEventListener(MouseEvent.MOUSE_DOWN, onStartDrawing);														ExternalInterface.addCallback("uploadDrawing", onUploadDrawing);						buildMenu();			onClear();		}				private function buildMenu():void {			var menuItem:ContextMenuItem;						_menu = new ContextMenu();			_menu.hideBuiltInItems();			_menu.addEventListener(ContextMenuEvent.MENU_SELECT, onShowMenu);						switch (_mode) {				case DRAW_MODE:					menuItem = new ContextMenuItem("Erase Mode");		            _menu.customItems.push(menuItem);		            menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onErase);					break;									case ERASE_MODE:					menuItem = new ContextMenuItem("Draw Mode");					_menu.customItems.push(menuItem);					menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDraw);					break;			}						menuItem = new ContextMenuItem("Undo Segment");			menuItem.separatorBefore = true;			menuItem.enabled = (_layers.length > 0);			            _menu.customItems.push(menuItem);            menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onUndo);						menuItem = new ContextMenuItem("Clear Doodle");				menuItem.separatorBefore = true;            _menu.customItems.push(menuItem);            menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onClear);			this.contextMenu = _menu;						}				private function onClear(evt:ContextMenuEvent = null):void {			var i:uint;			var max:uint = _layers.length;						for (i=0; i<max; ++i) {				_canvas.removeChild(_layers[i]);			}						_layers = new Array();						_maxX = 0;			_maxY = 0;						onDraw();		}				private function onUndo(evt:ContextMenuEvent = null):void {			var layer:Sprite = _layers.pop();						_canvas.removeChild(layer);						if (_layers.length == 0) {				buildMenu();			}		}				private function onDraw(evt:ContextMenuEvent = null):void {			if (_lastBrush != null) {				_brushes.removeChild(_lastBrush);				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackBrush);			}						_lastBrush = null;			Mouse.show();						_mode = DRAW_MODE;			buildMenu();		}				private function onErase(evt:ContextMenuEvent = null):void {			if (_lastBrush != null) {				_brushes.removeChild(_lastBrush);				stage.removeEventListener(MouseEvent.MOUSE_MOVE, trackBrush);			}						_lastBrush = _eraseBrush;			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackBrush);			_lastBrush.x = this.mouseX;			_lastBrush.y = this.mouseY;			Mouse.hide();			_brushes.addChild(_lastBrush);						_mode = ERASE_MODE;			buildMenu();					}				private function onShowMenu(evt:ContextMenuEvent = null):void {			onStopDrawing();		}				private function trackBrush(evt:MouseEvent):void {						_lastBrush.x = evt.stageX;			_lastBrush.y = evt.stageY;						evt.updateAfterEvent();		}				private function onStartDrawing(evt:MouseEvent):void {			var layer:Sprite = new Sprite();			_canvas.addChild(layer);			_layers.push(layer);			switch (_mode) {				case DRAW_MODE:					layer.graphics.lineStyle(0, 0);					break;									case ERASE_MODE:					layer.graphics.lineStyle(10, 0xFFFFFF);					break;			}									stage.removeEventListener(MouseEvent.MOUSE_DOWN, onStartDrawing);			stage.addEventListener(MouseEvent.MOUSE_MOVE, onDrawSegment);			stage.addEventListener(MouseEvent.MOUSE_UP, onStopDrawing);			stage.addEventListener(Event.MOUSE_LEAVE, onStopDrawing);						layer.graphics.moveTo(evt.stageX, evt.stageY);						_maxX = Math.max(_maxX, evt.stageX);			_maxY = Math.max(_maxY, evt.stageY);		}				private function onDrawSegment(evt:MouseEvent):void {			var layer:Sprite = _layers[_layers.length - 1];						layer.graphics.lineTo(evt.stageX, evt.stageY);						_maxX = Math.max(_maxX, evt.stageX);			_maxY = Math.max(_maxY, evt.stageY);						evt.updateAfterEvent();		}				private function onStopDrawing(evt:MouseEvent = null):void {			if (evt != null) {				onDrawSegment(evt);			}			if (_layers.length == 1) {				buildMenu();			}						stage.addEventListener(MouseEvent.MOUSE_DOWN, onStartDrawing);			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onDrawSegment);			stage.removeEventListener(MouseEvent.MOUSE_UP, onStopDrawing);			stage.removeEventListener(Event.MOUSE_LEAVE, onStopDrawing);					}				private function onUploadDrawing():void {			var loader:URLLoader = new URLLoader();			var serviceUrl:String = loaderInfo.parameters["service"];			var request:URLRequest = new URLRequest(serviceUrl);			var variables:URLVariables = new URLVariables();			var jpgData:ByteArray;			var jpgString:String;			var bitmapData:BitmapData;			var p:String;						request.method = URLRequestMethod.POST;			request.data = new Object();						// add flash vars to data sent out			/*			for (p in loaderInfo.parameters) {				if (p != "service") {					request.data[p] = loaderInfo.parameters[p];				}			}			*/						bitmapData = new BitmapData(_maxX + 15, _maxY + 15);			bitmapData.draw(_canvas);						jpgData = _jpgEncoder.encode(bitmapData);			jpgString = Base64.encodeByteArray(jpgData);						variables.drawing = jpgString;			request.data = variables;						loader.addEventListener(Event.COMPLETE, onUploadComplete);			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);			loader.load(request);					}				private function onUploadComplete(evt:Event):void {			ExternalInterface.call("onDrawingUploaded", URLLoader(evt.target).data);		}				private function onIOError(evt:IOErrorEvent):void {			ExternalInterface.call("onDrawingError", "IOError");		}				private function onSecurityError(evt:SecurityErrorEvent):void {			ExternalInterface.call("onDrawingError", "SecurityError");		}			}	}