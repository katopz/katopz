package com.sleepydesign.display
{
	import com.sleepydesign.core.IDestroyable;
	import com.sleepydesign.utils.DisplayObjectUtil;

	import flash.display.Sprite;

	public class SDSprite extends Sprite implements IDestroyable
	{
		protected var _isDestroyed:Boolean;

		public function get destroyed():Boolean
		{
			return _isDestroyed;
		}

		public function destroy():void
		{
			_isDestroyed = true;

			DisplayObjectUtil.removeChildren(this, true, true);

			try
			{
				if (parent != null)
					parent.removeChild(this);
			}
			catch (e:*)
			{
			}
		}
	}
}