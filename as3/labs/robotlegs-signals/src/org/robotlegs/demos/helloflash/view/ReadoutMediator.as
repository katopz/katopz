/*
 * Copyright (c) 2009 the original author or authors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.robotlegs.demos.helloflash.view
{
	import org.robotlegs.demos.helloflash.controller.HelloFlashSignal;
	import org.robotlegs.demos.helloflash.model.SomeModel;
	import org.robotlegs.demos.helloflash.model.StatsModel;
	import org.robotlegs.mvcs.Mediator;
	
	public class ReadoutMediator extends Mediator
	{
		[Inject]
		public var view:Readout;
		
		[Inject]
		public var statsModel:StatsModel;
		
		[Inject]
		public var hello:HelloFlashSignal;
		
		[Inject]
		public var someModel:SomeModel;
		
		public function ReadoutMediator()
		{
			// Avoid doing work in your constructors!
			// Mediators are only ready to be used when onRegister gets called
		}
		
		override public function onRegister():void
		{
			// Listen to the context
			//eventMap.mapListener(eventDispatcher, HelloFlashEvent.BALL_CLICKED, onBallClicked);
			hello.add(onBallClicked);
		}
		
		protected function onBallClicked(something:String):void//e:HelloFlashEvent):void
		{
			// Manipulate the view
			view.setText('Click count: ' + statsModel.ballClickCount + ":" + something + ":" + someModel.getLastVO());
		}
	}
}