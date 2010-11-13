package app.view.events
{
	import lib.events.CustomEvent;
	
	/**
	 * 		
	 * 		@author		Joao Pescada [joaopescada.com | hi@joaopescada.com]
	 * 		@created	2010/05/19 18:11
	 * 		@updated	2010/11/13 17:23	
	 * 		@version	1.0.1
	 * 
	 */
	public class UIEvent extends CustomEvent
	{
		public static const NAME:String = "UIEvent";
		public static const ANIMATION_3D_START:String = NAME + "_Animation3DStart";
		public static const ANIMATION_3D_END:String = NAME + "_Animation3DEnd";
		public static const ASSETS_LOAD_START:String = NAME + "_AssetsLoadStart";
		public static const ASSETS_LOAD_PROGRESS:String = NAME + "_AssetsLoadProgress";
		public static const ASSETS_LOAD_COMPLETE:String = NAME + "_AssetsLoadComplete";
		
		public function UIEvent(type:String, note:Object=null, bubbles:Boolean=false, cancelable:Boolean=true)
		{
			super(type, note, bubbles, cancelable);
		}
	}
}