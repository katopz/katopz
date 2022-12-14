package open3d.objects
{
	import flash.display.*;
	import flash.geom.*;
	
	import open3d.geom.Face;
	import open3d.materials.Material;
	
	/**
	 * Mesh
	 * @author katopz
	 */	
	public class Mesh extends Object3D
	{
		// public var faster than get/set
		public var faces:Vector.<Face>;
		protected var _faces:Vector.<Face>;
		
		// still need Array for sortOn(faster than Vector sort)
		private var _faceIndexes:Array;
		
		public function get numFaces():int
		{
			return _faceIndexes?_faceIndexes.length:0;
		}
		
		public function set culling(value:String):void
		{
			_triangles.culling = value;
		}
		
		private var _isFaceZSort:Boolean = true;
		public function set isFaceZSort(value:Boolean):void
		{
			_isFaceZSort = value;
		}
		
		private var _commands:Vector.<int> = new Vector.<int>(3, true); // commands to draw triangle
		private var _data:Vector.<Number>  = new Vector.<Number>(6, true); // data to draw shape

		public function Mesh()
		{
			_triangles = new GraphicsTrianglePath(new Vector.<Number>(), new Vector.<int>(), new Vector.<Number>(), TriangleCulling.POSITIVE);
			_commands[0] = 1;
			_commands[1] = 2;
			_commands[2] = 2;
		}

		protected function buildFaces(material:Material):void
		{
			var _indices:Vector.<int> = _triangles.indices;
			
			// numfaces
			var _indices_length:int = _indices.length / 3;
			
			_faces = new Vector.<Face>(_indices_length, true);
			_faceIndexes = [];
			
			var i0:uint, i1:uint, i2:uint;
			for (var i:int = 0; i < _indices_length; ++i)
			{
				// 3 point of face 
				var ix3:int = int(i*3);
				i0 = _indices[int(ix3 + 0)];
				i1 = _indices[int(ix3 + 1)];
				i2 = _indices[int(ix3 + 2)];
				
				// referer
				var index:Vector3D = new Vector3D(i0, i1, i2, 0);
				var _face:Face = _faces[i] = new Face(this, index, 
						new Vector3D(_vin[3 * i0 + 0], _vin[3 * i0 + 1], _vin[3 * i0 + 2]),
						new Vector3D(_vin[3 * i1 + 0], _vin[3 * i1 + 1], _vin[3 * i1 + 2]),
						new Vector3D(_vin[3 * i2 + 0], _vin[3 * i2 + 1], _vin[3 * i2 + 2])
					);
				
				// register face index for z-sort
				_faceIndexes[i] = index;
			}
			
			this.material = material;
			
			// for public call fadter than get/set
			faces = _faces;
			
			update();
		}
		
		/**
		 * must update once before project loop
		 */
		override public function update():void
		{
			super.update();
			
			// radius
			for each (var face:Face in _faces)
			{
				if(radius<face.length)
					radius = face.length;
			}
		}
		
		override public function project(camera:Camera3D):void
		{
			if(!_ready)return;
			
			super.project(camera);
			
			if(!_faceIndexes)return;
			var _faceIndexes_length:int = _faceIndexes.length;
			if(_faceIndexes_length<=0)return;
			
			// z-sort, TODO : only sort when transfrom is dirty
			if (_isFaceZSort)
			{
				// get last depth after projected
				for each (var _face:Face in _faces)
					_face.calculateScreenZ(_vout);
				
				// sortOn (faster than Vector.sort)
				_faceIndexes.sortOn("w", 18);
				
				// push back (faster than Vector concat)
				var _triangles_indices:Vector.<int> = _triangles.indices = new Vector.<int>(_faceIndexes_length * 3, true);
				var i:int = -1;
				for each(var index:Vector3D in _faceIndexes)
				{
					_triangles_indices[int(++i)] = index.x;
					_triangles_indices[int(++i)] = index.y;
					_triangles_indices[int(++i)] = index.z;
				}
			}
			
			// faster than getRelativeMatrix3D, also support current render method
			screenZ = _faceIndexes[int(_faceIndexes_length*.5)].w;
		}
		
		public function debugFace(x:Number, y:Number, _view_graphics:Graphics):void
		{
        	var _vertices:Vector.<Number> = _triangles.vertices;

			// TODO : promote this to face class somehow
        	var isHit:Boolean;
			_view_graphics.beginFill(0xFF0000, .5);
        	_view_graphics.lineStyle(1,0xFFFF00);
        	for each (var face:Face in _faces)
        	{
				// get path data grom face
				var _data:Vector.<Number> = face.getPathData(_vertices);
				
				// chk point in triangle
				if(insideTriangle(x, y, _data[0], _data[1], _data[2], _data[3], _data[4], _data[5]))
				{
					// DRAW TYPE #3 drawPath for ColorMaterial = faster than BitmapData-Color
					_view_graphics.drawPath(_commands, _data);
					/*
					// face normal debug
					_view_graphics.lineStyle(1,0xFFFF00);
					_view_graphics.moveTo(_data[6], _data[7]);
					_view_graphics.lineTo(_data[8], _data[9]);
					_view_graphics.lineStyle();
					*/
				}
        	}
        	_view_graphics.lineStyle();
        	_view_graphics.endFill();
		}
		
		
		override public function hitTestPoint(x:Number, y:Number, shapeFlag:Boolean=false):Boolean
		{
        	var _vertices:Vector.<Number> = _triangles.vertices;
        	var isHit:Boolean;
        	
        	for each (var face:Face in _faces)
        	{
				// get path data grom face
				var _data:Vector.<Number> = face.getPathData(_vertices);
				
				// chk point in triangle
				if(insideTriangle(x, y, _data[0], _data[1], _data[2], _data[3], _data[4], _data[5]))
					return true;
        	}
        	return false; 
		}
		
        /**
         * see if p is inside triangle abc
         * http://actionsnippet.com/?p=1462
         * 
         *      a 
         *     /\
         *    /p \
         *  b/____\c
         * 
         */        
        private function insideTriangle(px:Number, py:Number, ax:Number, ay:Number, bx:Number, by:Number, cx:Number, cy:Number):Boolean
        {
			var aX:Number, aY:Number, bX:Number, bY:Number
			var cX:Number, cY:Number, apx:Number, apy:Number;
			var bpx:Number, bpy:Number, cpx:Number, cpy:Number;
			var cCROSSap:Number, bCROSScp:Number, aCROSSbp:Number;

			aX = cx - bx;
			aY = cy - by;
			bX = ax - cx;
			bY = ay - cy;
			cX = bx - ax;
			cY = by - ay;
			
			apx = px - ax;
			apy = py - ay;
			bpx = px - bx;
			bpy = py - by;
			cpx = px - cx;
			cpy = py - cy;

			aCROSSbp = aX * bpy - aY * bpx;
			cCROSSap = cX * apy - cY * apx;
			bCROSScp = bX * cpy - bY * cpx;

			return (aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0);
        }
	}
}
