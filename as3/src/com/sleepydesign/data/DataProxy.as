package com.sleepydesign.data
{
	import flash.net.URLVariables;
	import flash.utils.Dictionary;

	import org.osflash.signals.Signal;

	public class DataProxy
	{
		public static var FLASH_VARS:String = "FLASH_VARS";

		private static var _datas:Dictionary;

		public static var dataSignal:Signal = new Signal(String, Object);

		public static function getData(id:String):*
		{
			if (_datas)
				return _datas[id];
			else
				return null;
		}

		public static function setData(id:String, data:*):*
		{
			if (!_datas)
				_datas = new Dictionary(true);

			_datas[id] = data;

			dataSignal.dispatch(id, data);

			return data;
		}

		public static function removeDataByID(id:String):void
		{
			if (!_datas)
				return;

			delete _datas[id];
			_datas[id] = null;

			// rebuild for gc
			var _tempDatas:Dictionary = new Dictionary(true);
			for (var _item:* in _datas)
				if (_datas[_item])
					_tempDatas[_item] = _datas[_item];
			_datas = _tempDatas;
		}

		public static function removeAllData():void
		{
			if (!_datas)
				return;

			for each (var id:* in _datas)
			{
				delete _datas[id];
				_datas[id] = null;
			}

			_datas = new Dictionary(true);
		}

		public static function getDataByVars(varsString:String):URLVariables
		{
			var _URLVariables:URLVariables = new URLVariables(varsString);
			var _resultURLVariables:URLVariables = new URLVariables();

			for (var _name:String in _URLVariables)
				_resultURLVariables[_name] = getData(_URLVariables[_name]);

			return _resultURLVariables;
		}

	/*
	   public static function setDataToQuery(varsString:String):String
	   {
	   var _URLVariables:URLVariables = getDataByVars(varsString);
	   for(var _var:String in _URLVariables)
	   varsString = varsString.split(_var).join("'"+getDataByID(_var.split("$").join(""))+"'");
	   return varsString;
	   }
	 */
	}
}