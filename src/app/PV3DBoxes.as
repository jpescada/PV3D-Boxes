package app
{
	import app.view.events.UIEvent;
	
	import com.greensock.TweenLite;
	import com.greensock.plugins.BezierPlugin;
	import com.greensock.plugins.TweenPlugin;
	
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import jiglib.math.JNumber3D;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.papervision3d.Papervision3DPhysics;
	import jiglib.plugin.papervision3d.constraint.MouseConstraint;
	
	import lib.geom.ShadowCaster;
	import lib.utils.Math2;
	
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.events.FileLoadEvent;
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.BitmapFileMaterial;
	import org.papervision3d.materials.MovieMaterial;
	import org.papervision3d.materials.WireframeMaterial;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Plane;
	import org.papervision3d.view.BasicView;
	import org.papervision3d.view.layer.ViewportLayer;
	import org.papervision3d.view.layer.util.ViewportLayerSortMode;
	
	/**
	 * 		
	 * 		@author		Joao Pescada [joaopescada.com | hi@joaopescada.com]
	 * 		@created	2010/05/20 11:08
	 * 		@updated	2010/11/13 17:28	
	 * 		@version	1.0.1
	 * 
	 */
	[SWF (width="960", height="600", frameRate="24", backgroundColor="#FFFFFF")]
	
	public class PV3DBoxes extends BasicView
	{
		public static const NAME:String = "PV3DBoxes";
		
		private const _BOXES_LIST:Array = 
			[
				{name:"purple", x:240, z:50},
				{name:"red", x:55, z:316},
				{name:"green", x:380, z:-227},
				{name:"beige", x:-432, z:-83},
				{name:"blue", x:-228, z:208},
				{name:"orange", x:-40, z:-290},
				{name:"brown", x:381, z:325}
			];
		private const _BOX_COLOR:int = 0xE3CCA7;
		private const _BIRD_VIEW:String = "BirdView";
		private const _SIDE_VIEW:String = "SideView";
		private const _GUI_MARGIN:int = 20;
		
		private var _isInited:Boolean = false;
		private var _areTexturesLoaded:Boolean = false;
		private var _texturesLoaded:int;
		private var _physics:Papervision3DPhysics;
		private var _mouseConstraint:MouseConstraint;
		private var _pointLight:PointLight3D;
		private var _cameraTarget:DisplayObject3D;
		private var _activeObject:DisplayObject3D;
		private var _shadowCaster:ShadowCaster;
		private var _boxesHolder:DisplayObject3D;
		private var _floor:Plane;
		private var _currentView:String = _BIRD_VIEW;
		private var _camButton:Sprite;
		private var _basePath:String = "";
		private var _boxesAdded:Array = [];
		private var _groundLayer:ViewportLayer;
		private var _boxesLayer:ViewportLayer;
		private var _groundImagesLayer:ViewportLayer;
		private var _delayedCall:Timer;
		private var _defaultStageQuality:String;
	
		
		public function PV3DBoxes()
		{
			super(960, 600, false, true/*, CameraType.DEBUG*/);
			
			TweenPlugin.activate( [BezierPlugin] );
			
			if (stage) _init();
			else addEventListener( Event.ADDED_TO_STAGE, _init );
		}
		
		public function startup():void
		{
			if (!_isInited) return;
			
			//reset camera
			camera.y = 1200;
			camera.z = -1;
			
			//reset boxes
			var mesh:DisplayObject3D;
			var box:RigidBody;
			var boxObj:Object;
			var boxesLen:int = _boxesAdded.length;
			for (var i:int = 0; i < boxesLen; i++)
			{
				boxObj = (_BOXES_LIST[i] as Object);
				box = _boxesAdded[i] as RigidBody;
				
				box.x = int( boxObj.x );//Math2.randRange( -300, 300 );
				box.y = 120/* + 80 * i*/;
				box.z = int( boxObj.z );//Math2.randRange( -300, 300 );
				box.rotationX = 180;
				box.rotationY = Math2.randRange( 160, 200 );
				box.mass = 10;
				box.addGravity();		
				
				mesh = _physics.getMesh( box );
				mesh.addEventListener( InteractiveScene3DEvent.OBJECT_OVER, _handleBoxRollOver );
				mesh.addEventListener( InteractiveScene3DEvent.OBJECT_OUT, _handleBoxRollOut );
				mesh.addEventListener( InteractiveScene3DEvent.OBJECT_PRESS, _handleBoxPress );
				
				//re-activate physics on box
				//box.setActive();
			}
		}
		
		public function destroy():void
		{
			this.parent.removeChild( this );
		}
				
		private function _init(evt:Event=null):void
		{
			removeEventListener( Event.ADDED_TO_STAGE, _init );
			addEventListener( Event.REMOVED_FROM_STAGE, _handleRemoved );
			
			trace("@ "+ NAME +"._init()");
			dispatchEvent( new UIEvent( UIEvent.ASSETS_LOAD_START ) );
			
			/*
			// NOTE: init is delayed to allow loading all libs into memory 
			
			_initStage();
			_initScene();
			
			_initPhysics();
			_initStaticObjects();
			_initInteractiveObjects();
			_initGUI();
			
			_handleStageResize();
			
			startRendering();
			
			_isInited = true;
			*/
			
			_delayedCall = new Timer(1000, 1);
			_delayedCall.addEventListener( TimerEvent.TIMER_COMPLETE, _delayedInit );
			_delayedCall.start();			
		}
		
		private function _delayedInit(evt:TimerEvent=null):void
		{
			//trace("@ "+ NAME +"._delayedInit()");			
			if (_delayedCall) _delayedCall.removeEventListener( TimerEvent.TIMER_COMPLETE, _delayedInit );
			
			_initStage();
			_initScene();
						
			_initPhysics();
			_initStaticObjects();
			_initInteractiveObjects();
			_initGUI();
			
			_handleStageResize();
			
			startRendering();
			
			_isInited = true;
		}
		
		private function _initStage():void
		{
			_defaultStageQuality = stage.quality;
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			//stage.quality = StageQuality.MEDIUM;
			
			stage.addEventListener( Event.RESIZE, _handleStageResize );
		}
		
		private function _initScene():void
		{
			//Camera defaults -> focus: 8.66 | zoom: 40
			//camera.focus = 10;
			//camera.zoom = 50;
			camera.fov = 40;
			//camera.x = 0.1; 
			camera.y = 1200;
			camera.z = -1;
			camera.lookAt( DisplayObject3D.ZERO );
			
			_pointLight = new PointLight3D();
			_pointLight.x = 0;
			_pointLight.y = 2000;
			_pointLight.z = 0;
			
			_shadowCaster = new ShadowCaster("shadow", 0x000000, BlendMode.NORMAL, 0.2, [ new BlurFilter(4, 4, BitmapFilterQuality.HIGH) ] );
			_shadowCaster.setType( ShadowCaster.SPOTLIGHT );
			
			_boxesLayer = new ViewportLayer( viewport, null );
			_groundLayer = new ViewportLayer( viewport, null );
			_groundImagesLayer = new ViewportLayer ( viewport, null );
			
			_boxesLayer.blendMode = BlendMode.LAYER;
			
			viewport.interactive = true;
			viewport.containerSprite.addLayer( _boxesLayer );
			viewport.containerSprite.addLayer( _groundImagesLayer );
			viewport.containerSprite.addLayer( _groundLayer );
			
			viewport.containerSprite.sortMode = ViewportLayerSortMode.INDEX_SORT;
			
			_groundLayer.layerIndex = 1;
			_groundImagesLayer.layerIndex = 2;
			_boxesLayer.layerIndex = 3;
			
			//addChild( new Stats() );		
		}
		
		private function _initPhysics():void
		{
			_physics = new Papervision3DPhysics( scene, 7 );
			_physics.engine.setGravity( new JNumber3D(0, -50, 0) );
		}
		
		private function _initStaticObjects():void
		{
			_initGround();
			//_initWalls();
		}
		
		private function _initInteractiveObjects():void
		{
			_boxesHolder = scene.addChild( new DisplayObject3D() );
			_initBoxes();
		}
		
		private function _initGUI():void
		{
			_initCamButton();
		}
		
		private function _initGround():void
		{
			var materials:MaterialsList = new MaterialsList();			
			var groundMat:WireframeMaterial = new WireframeMaterial(0xCCCCCC, 0);
			materials.addMaterial( groundMat, "all" );
			
			
			var ground:RigidBody = _physics.createGround( groundMat, 2000, 0 );
			//ground.friction = 1;
			ground.movable = false;
			
			var floorTile:Sprite = new Sprite();
			floorTile.graphics.beginFill( 0xFFFFFF );
			floorTile.graphics.drawRect( 0, 0, 256, 256 );
			floorTile.graphics.endFill();
			
			var floorMat:MovieMaterial = new MovieMaterial( floorTile, false, true, true );
			floorMat.interactive = true;
			_floor = new Plane( floorMat, 5000, 2000, 10, 10 );
			_floor.rotationX = 90;			
			scene.addChild( _floor );
						
			_groundLayer.addDisplayObject3D( _floor );			
		}
		
		private function _initWalls():void
		{
			//TODO: enforce wall as rigid bodies?
			var materials:MaterialsList = new MaterialsList();
			var wallMat:FlatShadeMaterial = new FlatShadeMaterial( _pointLight, 0xFFFFFF, 0xFFFFFF );
			materials.addMaterial( wallMat, "all" );
			
			var left:RigidBody = _physics.createCube( materials, 50, 1200, 1000 );
			left.movable = false;
			left.x = - 800;
			left.y = 260;
			
			var right:RigidBody = _physics.createCube( materials, 50, 1200, 1000 );
			right.movable = false;
			right.x = 800;
			right.y = 260;
			
			var back:RigidBody = _physics.createCube( materials, 1800, 50, 1000 );
			back.movable = false;
			back.z = 600;
			back.y = 260;
			
			/*
			var front:RigidBody = _physics.createCube( materials, 1800, 50, 1000 );
			front.movable = false;
			front.z = - 650;
			front.y = 260;
			*/
		}
		
		private function _initBoxes():void
		{
			var materials:MaterialsList = new MaterialsList();		
			
			//NOTE: textures are applied with a 180º rotation to avoid the "heavy-top" bug (?) while dragging
			
			var bmpMatTop:BitmapFileMaterial;

			var bmpMatBottom:BitmapFileMaterial = new BitmapFileMaterial("assets/images/textures/box_bottom.jpg");
			bmpMatBottom.addEventListener( FileLoadEvent.LOAD_COMPLETE, _handleTextureLoaded );
			
			var bmpMatFront:BitmapFileMaterial = new BitmapFileMaterial("assets/images/textures/box_front.jpg");
			bmpMatFront.addEventListener( FileLoadEvent.LOAD_COMPLETE, _handleTextureLoaded );
			
			var bmpMatBack:BitmapFileMaterial = new BitmapFileMaterial("assets/images/textures/box_back.jpg");
			bmpMatBack.addEventListener( FileLoadEvent.LOAD_COMPLETE, _handleTextureLoaded );
			
			var bmpMatRight:BitmapFileMaterial = new BitmapFileMaterial("assets/images/textures/box_right.jpg");
			bmpMatRight.addEventListener( FileLoadEvent.LOAD_COMPLETE, _handleTextureLoaded );
			
			var bmpMatLeft:BitmapFileMaterial = new BitmapFileMaterial("assets/images/textures/box_left.jpg");
			bmpMatLeft.addEventListener( FileLoadEvent.LOAD_COMPLETE, _handleTextureLoaded );
			
			bmpMatBottom.smooth = bmpMatFront.smooth = bmpMatBack.smooth = bmpMatRight.smooth = bmpMatLeft.smooth = true;
			//bmpMatBottom.doubleSided = bmpMatFront.doubleSided = bmpMatBack.doubleSided = bmpMatRight.doubleSided = bmpMatLeft.doubleSided = true;
			bmpMatBottom.interactive = bmpMatFront.interactive = bmpMatBack.interactive = bmpMatRight.interactive = bmpMatLeft.interactive = true;
			bmpMatBottom.fillColor = bmpMatFront.fillColor = bmpMatBack.fillColor = bmpMatRight.fillColor = bmpMatLeft.fillColor = _BOX_COLOR;
			
			var wireMat:WireframeMaterial = new WireframeMaterial(0xFF4444);
			wireMat.interactive = true;
			
			var flatMat:FlatShadeMaterial = new FlatShadeMaterial( _pointLight, _BOX_COLOR, _BOX_COLOR );
			flatMat.interactive = true;		
			
			materials.addMaterial( flatMat, "all" );
			materials.addMaterial( bmpMatBottom, "top" );
			materials.addMaterial( bmpMatFront, "back" );
			materials.addMaterial( bmpMatBack, "front" );
			materials.addMaterial( bmpMatRight, "left" );
			materials.addMaterial( bmpMatLeft, "right" );
			
			var mesh:DisplayObject3D;
			
			//var box:Cube;
			var box:RigidBody;
			
			var boxesLen:int = _BOXES_LIST.length;
			var boxObj:Object;
			
			for (var i:int = 0; i < boxesLen; i++)
			{
				boxObj = (_BOXES_LIST[i] as Object);
				
				bmpMatTop = new BitmapFileMaterial("assets/images/textures/box_top_"+ boxObj.name +".jpg", true);
				bmpMatTop.smooth = true;
				//bmpMatTop.doubleSided = true;
				bmpMatTop.interactive = true;
				bmpMatTop.fillColor = _BOX_COLOR;
				bmpMatTop.addEventListener( FileLoadEvent.LOAD_COMPLETE, _handleTextureLoaded );
				
				materials.addMaterial( bmpMatTop, "bottom" );
				
				box = _physics.createCube( materials, 200, 200, 200, 3, 3, 3 );
				//box = new Cube( materials, 200, 200, 200, 3, 3, 3 );
				
				box.x = int( boxObj.x );//Math2.randRange( -300, 300 );
				box.y = 120/* + 80 * i*/;
				box.z = int( boxObj.z );//Math2.randRange( -300, 300 );
				box.rotationX = 180;
				box.rotationY = Math2.randRange( 160, 200 );//180;
				box.mass = 10;
				box.addGravity();
				
				mesh = _physics.getMesh( box );
				mesh.addEventListener( InteractiveScene3DEvent.OBJECT_OVER, _handleBoxRollOver );
				mesh.addEventListener( InteractiveScene3DEvent.OBJECT_OUT, _handleBoxRollOut );
				mesh.addEventListener( InteractiveScene3DEvent.OBJECT_PRESS, _handleBoxPress );
				
				_boxesHolder.addChild( mesh, "box"+ i );
				_boxesLayer.addDisplayObject3D( mesh );
				
				// store in array for easy access later
				_boxesAdded.push( box );				
			}
		}
		
		private function _initCamButton():void
		{
			_camButton = new Sprite()
			//_camButton.name = "camButton";
			var txtFmt:TextFormat = new TextFormat("Arial", 12, 0xFFFFFF, true);
			var txt:TextField = new TextField();
			txt.defaultTextFormat = txtFmt;
			txt.text = "Change View";
			txt.textColor = 0xFFFFFF;
			txt.x = 5;
			txt.y = 5;
			txt.autoSize = TextFieldAutoSize.LEFT;
			txt.selectable = false;
			
			_camButton.graphics.beginFill( 0x000000 );
			_camButton.graphics.drawRoundRect( 0, 0, txt.textWidth + 12, txt.textHeight + 12, 10, 10 );
			_camButton.graphics.endFill();
			_camButton.buttonMode = true;
			_camButton.mouseChildren = false;
			_camButton.x = _GUI_MARGIN;
			_camButton.y = _GUI_MARGIN;
			
			_camButton.addChild( txt );
			addChild( _camButton );
			
			_camButton.addEventListener( MouseEvent.CLICK, _handleButtonClick );
		}
		
		private function _handleTextureLoaded(evt:FileLoadEvent):void
		{
			_texturesLoaded++;
			
			if (_texturesLoaded == 12)
			{
				_areTexturesLoaded = true;
				dispatchEvent( new UIEvent( UIEvent.ASSETS_LOAD_COMPLETE ) );
			}
		}
				
		private function _handleButtonClick(evt:MouseEvent):void
		{
			if (_currentView == _SIDE_VIEW) _moveCameraToBirdView();
			else _moveCameraToSideView();			
		}
		
		private function _handleRemoved(evt:Event):void
		{
			//trace("@ "+ NAME +"._handleRemoved()");
			removeEventListener(Event.REMOVED_FROM_STAGE, _handleRemoved );
			_removeListeners();
		}
		
		private function _removeListeners():void
		{
			if (_delayedCall) _delayedCall.removeEventListener( TimerEvent.TIMER_COMPLETE, _delayedInit );
			
			var mesh:DisplayObject3D;
			var len:int = _boxesAdded.length;
			for (var i:int=0; i < len; i++)
			{
				mesh = _physics.getMesh( _boxesAdded[i] );
				mesh.removeEventListener( InteractiveScene3DEvent.OBJECT_OVER, _handleBoxRollOver );
				mesh.removeEventListener( InteractiveScene3DEvent.OBJECT_OUT, _handleBoxRollOut );
				mesh.removeEventListener( InteractiveScene3DEvent.OBJECT_PRESS, _handleBoxPress );
			}
			
			stage.removeEventListener( MouseEvent.MOUSE_UP, _removeMouseConstraint );
			stage.removeEventListener( Event.RESIZE, _handleStageResize );
			
			if (_camButton) _camButton.removeEventListener( MouseEvent.CLICK, _handleButtonClick );
		}
		
		private function _handleBoxRollOver(evt:InteractiveScene3DEvent):void
		{
			//trace("@ "+ NAME +"._handleBoxRollOver()", evt.displayObject3D);
			var box:DisplayObject3D = evt.displayObject3D;
			//TweenLite.to( box, 1, {y:400} );
			//createSubmenu( box );
		}
		
		private function _handleBoxRollOut(evt:InteractiveScene3DEvent):void
		{
			//trace("@ "+ NAME +"._handleBoxRollOut()", evt.displayObject3D);
		}
		
		private function _handleBoxPress(evt:InteractiveScene3DEvent):void
		{
			_activeObject = evt.displayObject3D;
			//trace("@ "+ NAME +"._handleBoxPress()", _activeObject);
			_mouseConstraint = new MouseConstraint( _activeObject, new Number3D(0, 1, 0), camera, viewport );
			stage.quality = StageQuality.LOW;
			dispatchEvent( new UIEvent( UIEvent.ANIMATION_3D_START ) );
			stage.addEventListener( MouseEvent.MOUSE_UP, _removeMouseConstraint );
		}
		
		private function _removeMouseConstraint(evt:MouseEvent):void
		{
			stage.removeEventListener( MouseEvent.MOUSE_UP, _removeMouseConstraint );
			//trace("\t--RESET STAGE QUALITY", _defaultStageQuality);
			stage.quality = _defaultStageQuality;
			dispatchEvent( new UIEvent( UIEvent.ANIMATION_3D_END ) );
			
			_mouseConstraint.destroy();
			_mouseConstraint = null;
		}
		
		private function _moveCameraToBirdView():void
		{
			//trace("@ "+ NAME +"._moveCameraToBirdView()", camera.x, camera.y, camera.z, " | ", camera.target.x, camera.target.y, camera.target.z," | ", camera.rotationX, camera.rotationY, camera.rotationZ);
			
			dispatchEvent( new UIEvent( UIEvent.ANIMATION_3D_START ) );
			
			//camera.z = 0;			
			TweenLite.to(camera, 2, {y:1200, z:-1, 
				/*rotationX:0, rotationY:-90, rotationZ:0,*/
				onStart:function():void
				{
					stage.quality = StageQuality.LOW;
				},
				onComplete:function():void
				{
					//trace("\t--RESET STAGE QUALITY", _defaultStageQuality);
					stage.quality = _defaultStageQuality;
					_currentView = _BIRD_VIEW;
					
					dispatchEvent( new UIEvent( UIEvent.ANIMATION_3D_END ) );
					
					//trace("\tmoveCameraToBirdView COMPLETE", camera.x, camera.y, camera.z, " | ", camera.rotationX, camera.rotationY, camera.rotationZ);
				}
			});
			
			//TweenLite.to(_floor, 1, {y:-50});
		}
		
		private function _moveCameraToSideView():void
		{
			/*
			Default:
			camera.x = 1;
			camera.y = 1200;
			camera.z = 1;
			*/
			//camera.orbit(75, 0, true, _cameraTarget );
			//trace("@ "+ NAME +"._moveCameraToSideView()", camera.x, camera.y, camera.z, " | ", camera.target.x, camera.target.y, camera.target.z," | ", camera.rotationX, camera.rotationY, camera.rotationZ);
			
			dispatchEvent( new UIEvent( UIEvent.ANIMATION_3D_START ) );
			
			TweenLite.to(camera, 2, {
				bezier:
				[
					{y:1200, z:-1},
					{y:800, z:-500},
					{y:800, z:-1200}
				],
				/*rotationX:0, rotationY:-90, rotationZ:0, */
				onStart:function():void
				{
					stage.quality = StageQuality.LOW;
				},
				onComplete:function():void
				{
					//trace("\t--RESET STAGE QUALITY", _defaultStageQuality);
					stage.quality = _defaultStageQuality;
					_currentView = _SIDE_VIEW;
					
					dispatchEvent( new UIEvent( UIEvent.ANIMATION_3D_END ) );
					//trace("\tmoveCameraToSideView COMPLETE", camera.x, camera.y, camera.z, " | ", camera.rotationX, camera.rotationY, camera.rotationZ);
				}
			});
			
			//TweenLite.to(_floor, 1, {y:0});
		}
		
		private function _bringCubesBack():void
		{
			if (!stage) return;

			var len:int = _boxesAdded.length;
			for (var i:int=0; i < len; i++)
			{
				var box:RigidBody = _boxesAdded[i] as RigidBody;
				var hLimit:Number = stage.stageWidth * 0.8;
				var vLimit:Number = stage.stageHeight * 0.8;				
					
				if ( box && box.currentState.position.x && box.currentState.position.z && 
						(
						box.currentState.position.x < -hLimit || box.currentState.position.x > hLimit
						||
						box.currentState.position.z < -vLimit || box.currentState.position.z > vLimit
						)
					)
				{
					box.moveTo( new JNumber3D( Math2.randRange(-480, 480), Math2.randRange(600, 1200), Math2.randRange(-300, 300) ) );
				}
			}
		}
		
		private function _handleStageResize(evt:Event=null):void
		{
			if (!stage) return;

			//trace("@ "+ NAME +"._handleStageResize()", stage.align, stage.scaleMode);

			//TODO: change render area
			this.viewport.viewportWidth = stage.stageWidth;
			this.viewport.viewportHeight = stage.stageHeight;
		}
		
		override protected function onRenderTick(evt:Event=null):void
		{
			if (!stage) return;
			
			_shadowCaster.invalidate();
			_shadowCaster.castModel( _boxesHolder, _pointLight, _floor );
			
			_physics.step();
			
			_bringCubesBack();			
			
			super.onRenderTick( evt );
		}
	}
}