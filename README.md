# React #
React lets you turn JavaScript objects into reactive data.

React is a jQuery plugin that allows you to use aspect oriented
programming techniques to **react** to data changes of JavaScript
objects. This lets you do event driven programming on pure objects,
similar to the DOM, creating **reactive data**.

React works without base classes or changes to the JavaScript object
model, in the simplest case you simply hook up to any object variable,
such as an object returned from a JSON REST service. This sets it apart
from other data binding or event libraries.

~~~
var x = {
  a: 'Hello',
  b: 'World'
}
$(x).react('before', function(object, attribute, value){console.log(value)})
$(x).react('after', function(object, attribute, value){console.log(value)})
x.a = 'Yo'
x.b = 'Globe'
//Unhook all callbacks
$(x).react('off')
~~~

## Bubbling ##
React has a bubbling concept just like the DOM. Changes and property
accesses deep in an object bubble up to the root where you first
installed react. You can also set up hierarchies so that multiple
callbacks are fired.

~~~
var x = {
  nested: {
    a: 'Hello'
  }
}
$(x).react('before after', 
    function(object, attribute, value){console.log('root', value)})
$(x.nested).react('before after', 
    function(object, attribute, value){console.log('nested', value)})
x.nested.a = 'Hello World' //fires both callbacks above, deep.nested first
~~~

# Limitations #
React only works on attributes, whether string, object, number, or
array, not on functions inside objects.

Given that `Object.__noSuchMethod__` is not yet standard, there isn't yet a very
portable way to react to adding a property, so if you dynamically expand
an object, you need to react to it again. There is a shorthand for this
so you don't need to rebind all your event handlers.

~~~
//Continuing the example...
x.c = 'Stuff!' //dynamically added property
$(x).react() //refresh any proxying
x.c = 'Hot Stuff!'
~~~ 

## Internet Explorer 8 ##
The 'broken' DOM only IE implementation of `Object.defineProperty` will
need a polyfill to shim it up. Take a peek at
[es5-shim](https://github.com/kriskowal/es5-shim). I didn't include this
directly as you may have a different preference in polyfill, or just
plain not need to mess with IE8 if you are making a mobile application.

# Requirements #
React's tests are built with Jasmine, and the supplied Rakefile works
with jasmine-headless-webkit, which relies on QT in order to run. On my
Mac this is just `brew install qt`.

I've coded this up in CoffeeScript, which is really just a personal
preference, but you can just use the react.min.js in the root of the
repository.
