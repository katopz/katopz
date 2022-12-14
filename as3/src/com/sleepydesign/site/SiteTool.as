package com.sleepydesign.site
{
	import com.sleepydesign.core.IDestroyable;
	import com.sleepydesign.net.LoaderUtil;
	import com.sleepydesign.net.URLUtil;
	import com.sleepydesign.system.DebugUtil;
	import com.sleepydesign.system.SystemUtil;
	import com.sleepydesign.utils.DisplayObjectUtil;
	import com.sleepydesign.utils.StringUtil;
	import com.sleepydesign.utils.XMLUtil;

	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;

	import org.osflash.signals.Signal;

	public class SiteTool implements IDestroyable
	{
		private var _xml:XML;
		private var _container:DisplayObjectContainer;

		private var _currentPaths:Array = [];

		private var _page:Page;
		private static var _currentPage:Page;

		private var _currentPageID:String;

		private static var _instance:SiteTool;

		public static function currentPage():Page
		{
			return _currentPage;
		}

		public static function getInstance():SiteTool
		{
			if (_instance)
				return _instance;
			else
				throw new Error("SiteTool didn't init yet?");
		}

		public function SiteTool(container:DisplayObjectContainer = null, xml:XML = null)
		{
			_instance = this;

			_container = container;
			_xml = xml;

			// root page
			_page = new Page(_container, _xml, _xml.@focus);
			_page.name = "site";

			// add pregress via root page
			_page.loadSignal.add(onLoad);
		}

		public var loadSignal:Signal = new Signal(int /*bytesLoaded*/, int /*bytesTotal*/);

		private function onLoad(bytesLoaded:int, bytesTotal:int):void
		{
			loadSignal.dispatch(bytesLoaded, bytesTotal);
		}

		public function setFocusByPath(path:String):void
		{
			DebugUtil.trace(" ! setFocusByPath : " + path);
			DebugUtil.trace(" ! currentPaths : " + _currentPaths);

			var _paths:Array = path.split("/");
			if (_paths[0] == "")
				_paths.shift();

			var _basePage:Page = _page;

			/*
			   var j:int = _basePage.numChildren;
			   while (j--)
			   DebugUtil.trace("*"+_basePage.getChildAt(j).name);
			 */

			// not dirty yet
			Page.preferPaths = Page.offerPaths = _paths.slice();

			// external?
			var _focusXML:XML = XMLUtil.getXMLById(_xml, path.split("/").pop());
			if (URLUtil.isURL(_focusXML.@src) && String(_focusXML.@src).indexOf(".swf") == -1)
			{
				// not getURL yet (twice call from external tree/site)
				if (_currentPaths.toString() != _paths.toString())
				{
					URLUtil.getURL(_focusXML.@src, _focusXML.@target);
					_currentPaths = _paths.slice();
					DebugUtil.trace(" ! _currentPaths : " + _currentPaths);
				}
				return;
			}

			// for destroy
			var _prevPageID:String = _currentPageID;

			for (var i:int = 0; i < _paths.length; i++)
			{
				var _pathID:String = _paths[i];
				var _subPage:Page = _basePage.getChildByName(_pathID) as Page;

				// redirect
				if (Page.preferPaths != Page.offerPaths)
					continue;

				var _childIndex:int = -1;

				// destroy last page if diff with old pages sequence
				if (_currentPaths.length > 0 && _currentPaths[i] && _paths[i] != _currentPaths[i])
				{
					/*
					   var j:int = _basePage.numChildren;
					   while (j--)
					   DebugUtil.trace(_basePage.getChildAt(j).name);
					 */

					DebugUtil.trace(" - remove Page : " + _currentPaths[i]);

					var _oldPage:Page = _basePage.getChildByName(_currentPaths[i]) as Page;

					if (!_oldPage)
					{
						DebugUtil.trace(" - remove Page : " + _prevPageID);
						_oldPage = _basePage.getChildByName(_prevPageID) as Page;
					}

					if (_oldPage)
					{
						_childIndex = _oldPage.parent.getChildIndex(_oldPage);

						_oldPage.destroy();
						_oldPage = null;

						SystemUtil.gc();
					}
				}

				if (!_subPage)
				{
					// new page
					var _itemXML:XML = XMLUtil.getXMLById(_xml, _pathID);

					if (StringUtil.isNull(_itemXML))
					{
						_basePage.focus = _pathID;
						continue;
					}

					DebugUtil.trace(" + add Page : ", _childIndex, _pathID);

					_subPage = new Page(_basePage, _itemXML, _paths.slice(i + 1).join("/"));
					_subPage.name = _pathID;

					if (_childIndex >= 0)
					{
						_basePage.removeChild(_subPage);
						_basePage.addChildAt(_subPage, _childIndex);
					}

					DebugUtil.trace(" to : " + _basePage.name);
				}

				// reparent
				if (_subPage)
					_basePage = _subPage;

				// for destroy later
				_currentPageID = _pathID;

				// for referer from other
				_currentPage = _basePage;
			}

			// keep for destroy chain later
			_currentPaths = _paths.slice();

			// wait for next turn if someone make it dirty
			if (Page.preferPaths == Page.offerPaths)
				LoaderUtil.start();
			else
				setFocusByPath(Page.preferPaths.join("/"));
		}

		// ____________________________________________ Destroy ____________________________________________

		private var _isDestroyed:Boolean;

		public function get destroyed():Boolean
		{
			return this._isDestroyed;
		}

		public function destroy():void
		{
			super.destroy();

			_currentPaths = null;
			_page = null;
		}
	}
}