/**
 * Morn UI Version 2.1.0623 http://code.google.com/p/morn https://github.com/yungzhu/morn
 * Feedback yungzhu@gmail.com http://weibo.com/newyung
 */
package morn.core.components {
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import morn.core.events.UIEvent;
	import morn.core.handlers.Handler;
	import morn.editor.core.IList;
	
	/**选择项改变后触发*/
	[Event(name="select",type="flash.events.Event")]
	/**项渲染时触发*/
	[Event(name="listRender",type="morn.core.events.UIEvent")]
	
	/**列表*/
	public class List extends Box implements IItem, IList {
		protected var _items:Vector.<Component>;
		protected var _renderHandler:Handler;
		protected var _length:int;
		protected var _itemCount:int;
		protected var _page:int;
		protected var _totalPage:int;
		protected var _scrollBar:ScrollBar;
		protected var _scrollSize:int = 1;
		protected var _startIndex:int;
		protected var _selectedIndex:int = -1;
		protected var _array:Array = [];
		protected var _selectHandler:Handler;
		protected var _clickHandler:Handler;
		
		protected var _mouseDownHandler:Handler;
		protected var _mouseUpHandler:Handler;
		private var _spaceX:int;
		private var _spaceY:int;
		private var _repeatX:int;
		private var _repeatY:int;

		public function get spaceX():int
		{
			return _spaceX;
		}

		public function set spaceX(value:int):void
		{
			_spaceX = value;
		}

		public function get spaceY():int
		{
			return _spaceY;
		}

		public function set spaceY(value:int):void
		{
			_spaceY = value;
		}

		public function get repeatX():int
		{
			return _repeatX;
		}

		public function set repeatX(value:int):void
		{
			_repeatX = value;
		}

		public function get repeatY():int
		{
			return _repeatY;
		}

		public function set repeatY(value:int):void
		{
			_repeatY = value;
		}

		public function get isRemoveToCreate():Boolean
		{
			return _isRemoveToCreate;
		}

		public function set isRemoveToCreate(value:Boolean):void
		{
			_isRemoveToCreate = value;
		}

		public function get renderClass():Class
		{
			return _renderClass;
		}

		public function set renderClass(value:Class):void
		{
			_renderClass = value;
		}


		private var _isRemoveToCreate:Boolean = false;
		private var _renderClass:Class;
		
		/**批量设置列表项*/
		public function setItems(items:Array):void {
			removeAllChild(_scrollBar);
			var index:int = 0;
			for (var i:int = 0, n:int = items.length; i < n; i++) {
				var item:Component = items[i];
				if (item) {
					item.name = "item" + index;
					addChildAt(item, 0);
					index++;
				}
			}
			initItems();
		}
		
		/**增加列表项*/
		public function addItem(item:Component):void {
			item.name = "item" + _items.length;
			addChildAt(item, 0);
			initItems();
		}
		
		/**初始化列表项*/
		public function initItems():void {
			_scrollBar = getChildByName("scrollBar") as ScrollBar;
			if (_scrollBar) {
				_scrollBar.scrollSize = _scrollSize;
				_scrollBar.addEventListener(Event.CHANGE, onScrollBarChange);
				addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			
			_items = new Vector.<Component>();
			for (var i:int = 0; i < int.MAX_VALUE; i++) {
				var item:Component = getChildByName("item" + i) as Component;
				if (item == null) {
					break;
				}
				item.addEventListener(MouseEvent.MOUSE_DOWN, onItemMouse);
				item.addEventListener(MouseEvent.MOUSE_UP, onItemMouse);
				item.addEventListener(MouseEvent.CLICK, onItemMouse);
				if (item.getChildByName("selectBox")) {
					item.addEventListener(MouseEvent.ROLL_OVER, onItemMouse);
					item.addEventListener(MouseEvent.ROLL_OUT, onItemMouse);
				}
				_items.push(item);
			}
			_itemCount = _items.length;
		}
		
		protected function onMouseWheel(e:MouseEvent):void {
			_scrollBar.value -= e.delta;
		}
		
		protected function onItemMouse(e:MouseEvent):void {
			var item:Component = e.currentTarget as Component;
			var index:int = _startIndex + _items.indexOf(item);
			if (e.type == MouseEvent.MOUSE_DOWN) {
				selectedIndex = index;
				if(_mouseDownHandler != null){
					_mouseDownHandler.executeWith([_selectedIndex]);
				}
			}else if(e.type == MouseEvent.MOUSE_UP){
				if(_mouseUpHandler != null){
					_mouseUpHandler.executeWith([_selectedIndex]);
				}
			}else if(e.type == MouseEvent.CLICK){
				if(_clickHandler != null){
					_clickHandler.executeWith([_selectedIndex]);
				}
			}else if (_selectedIndex != index) {
				changeItemState(item, e.type == MouseEvent.ROLL_OVER, 0);
			}
		}
		
		protected function changeItemState(item:Component, visable:Boolean, frame:int):void {
			var selectBox:Clip = item.getChildByName("selectBox") as Clip;
			if (selectBox) {
				selectBox.visible = visable;
				selectBox.frame = frame;
			}
		}
		
		/**选择索引*/
		public function get selectedIndex():int {
			return _selectedIndex;
		}
		
		public function set selectedIndex(value:int):void {
			var oldValue:int = _selectedIndex;
			_selectedIndex = (value < -1 ? -1 : (value >= _array.length ? _array.length - 1 : value));
			
			if (oldValue != _selectedIndex) {
				setSelectStatus();
				sendEvent(Event.SELECT);
				if (_selectHandler != null) {
					_selectHandler.executeWith([_selectedIndex]);
				}
			}
		}
		
		protected function setSelectStatus():void {
			for (var i:int = 0, n:int = items.length; i < n; i++) {
				changeItemState(items[i], _selectedIndex == _startIndex + i, 1);
			}
		}
		
		/**选择被改变时执行的处理器(默认返回参数index:int)*/
		public function get selectHandler():Handler {
			return _selectHandler;
		}
		
		public function set selectHandler(value:Handler):void {
			_selectHandler = value;
		}
		
		/**选择项数据*/
		public function get selectedItem():Object {
			return _selectedIndex != -1 ? _array[_selectedIndex] : null;
		}
		
		public function set selectedItem(value:Object):void {
			selectedIndex = _array.indexOf(value);
		}
		
		/**选择项组件*/
		public function get selection():Component {
			return _selectedIndex != -1 ? _items[(_selectedIndex - _startIndex) % _itemCount] : null;
		}
		
		public function set selection(value:Component):void {
			selectedIndex = _startIndex + _items.indexOf(value);
		}
		
		protected function onScrollBarChange(e:Event):void {
			var start:int = Math.round(_scrollBar.value);
			if (_startIndex != start) {
				startIndex = start;
			}
		}
		
		/**当前页码*/
		public function get page():int {
			return _page;
		}
		
		public function set page(value:int):void {
			_page = (value < 0 ? 0 : (value >= _totalPage - 1 ? _totalPage - 1 : value));
			_startIndex = _page * _itemCount;
			callLater(refresh);
		}
		
		/**开始索引*/
		public function get startIndex():int {
			return _startIndex;
		}
		
		public function set startIndex(value:int):void {
			_startIndex = value > 0 ? value : 0;
			for (var i:int = 0; i < _itemCount; i++) {
				renderItem(_items[i], _startIndex + i);
			}
		}
		
		protected function renderItem(item:Component, index:int):void {
			if (index < _array.length) {
				item.visible = true;
				item.dataSource = _array[index];
			} else {
				item.visible = false;
			}
			setSelectStatus();
			if (_renderHandler != null) {
				_renderHandler.executeWith([item, index]);
			}
			sendEvent(UIEvent.ITEM_RENDER, [item, index]);
		}
		
		/**列表项处理器(默认返回参数item:Component,index:int)*/
		public function get renderHandler():Handler {
			return _renderHandler;
		}
		
		public function set renderHandler(value:Handler):void {
			_renderHandler = value;
		}
		
		/**刷新列表*/
		public function refresh():void {
			startIndex = _startIndex;
		}
		
		/**项集合*/
		public function get items():Vector.<Component> {
			return _items;
		}
		
		/**列表数据*/
		public function get array():Array {
			return _array;
		}
		
		public function set array(value:Array):void {
			_array = value || [];
			var length:int = _array.length;
			_totalPage = Math.ceil(length / _itemCount);
			//重设当前选择项
			selectedIndex = _selectedIndex;
			//重设开始相
			callLater(refresh);
			if (_scrollBar) {
				//自动隐藏滚动条
				_scrollBar.visible = length > _itemCount;
				_scrollBar.setScroll(0, Math.max(length - _itemCount, 0), _startIndex);
				if (_scrollBar.visible) {
					_scrollBar.thumbPercent = _itemCount / length;
				}
			}
		}
		
		/**滚动条*/
		public function get scrollBar():ScrollBar {
			return _scrollBar;
		}
		
		/**列表数据总数*/
		public function get length():int {
			return _array.length;
		}
		
		override public function set dataSource(value:Object):void {
			_dataSource = value;
			if (value is Array) {
				if(_isRemoveToCreate == true)
				{
					removeToCreateItems();
				}
				array = value as Array
			} else {
				super.dataSource = value;
			}
		}
		
		/**
		 * 给List赋值
		 * @param data
		 * @param repeatX
		 * @param repeatY
		 * 
		 */
		public function setDataSource(data:Object, repeatX:int, repeatY:int):void
		{
			this.repeatX = repeatX;
			this.repeatY = repeatY;
			this.dataSource = data;
			sendEvent(Event.RESIZE);
		}
		
		private function removeToCreateItems():void
		{
			removeAllChild(_scrollBar);
			if(!_renderClass){
				throw new Error("Can not found render class.");
			}
			for (var k:int = 0; k < _repeatY; k++) {
				for (var l:int = 0; l < _repeatX; l++) {
					var item:Component = new _renderClass();
					item.name = "item" + (l + k * _repeatX);
					item.x += l * (_spaceX + item.width);
					item.y += k * (_spaceY + item.height);
					addChild(item);
				}
			}
			initItems();
		}
		
		/**滚动单位*/
		public function get scrollSize():int {
			return _scrollSize;
		}
		
		public function set scrollSize(value:int):void {
			if (_scrollBar) {
				_scrollBar.scrollSize = value;
			}
		}
		
		/**最大分页数*/
		public function get totalPage():int {
			return _totalPage;
		}
		
		public function set totalPage(value:int):void {
			_totalPage = value;
		}

		/**
		 * render数量
		 */
		public function get itemCount():int
		{
			return _itemCount;
		}

		/**
		 * 点击时触发
		 */
		public function get clickHandler():Handler
		{
			return _clickHandler;
		}

		/**
		 * @private
		 */
		public function set clickHandler(value:Handler):void
		{
			_clickHandler = value;
		}

		/**
		 * 鼠标抬起触发
		 */
		public function get mouseUpHandler():Handler
		{
			return _mouseUpHandler;
		}

		public function set mouseUpHandler(value:Handler):void
		{
			_mouseUpHandler = value;
		}

		/**
		 * 鼠标按下触发
		 */
		public function get mouseDownHandler():Handler
		{
			return _mouseDownHandler;
		}

		/**
		 * @private
		 */
		public function set mouseDownHandler(value:Handler):void
		{
			_mouseDownHandler = value;
		}


	}
}