/* @module watch
 *
 * Provides a polyfill installing the
 * [`watch`](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/watch)
 * and [`unwatch`](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/unwatch)
 * methods as defined on MDN.
 *
 */
if (!Object.prototype.watch) {
    Object.defineProperty(Object.prototype, "watch", {
        enumerable: false
        , configurable: true
        , writable: false
        , value: function (prop, handler) {
            var
            oldval = this[prop]
            , newval = oldval
            , getter = function () {
                return newval;
            }
            , setter = function (val) {
                oldval = newval;
                return newval = handler.call(this, prop, oldval, val);
            }
            ;

            if (delete this[prop]) { // can't watch constants
                Object.defineProperty(this, prop, {
                    get: getter
                    , set: setter
                    , enumerable: true
                    , configurable: true
                });
            }
        }
    });
}

// object.unwatch
if (!Object.prototype.unwatch) {
    Object.defineProperty(Object.prototype, "unwatch", {
        enumerable: false
        , configurable: true
        , writable: false
        , value: function (prop) {
            var val = this[prop];
            delete this[prop]; // remove accessors
            this[prop] = val;
        }
    });
}
/*
@module proxy

Provides the ability to wrap any object with a proxy that sets up
interception callbacks on any property set or nested array mutation.
This sets a foundation for aspect oriented style JavaScript.

Proxied properties are tracked in `__proxied__`, which is made
non-enumerable via Object.defineProperty in order to keep it out of
JSON going back to your server, as well as showing up in normal loop
iteration. Be warned that on IE8 that needs a `Object.defineProperty`
polyfill, this can end up visible.
*/


/*
@private
List of methods on Array that mutate it in place.
*/


(function() {
  var after, array_mutators, before, proxyObject;

  array_mutators = ['push', 'unshift', 'pop', 'shift', 'reverse', 'sort', 'splice'];

  /*
  @function
  
  Given an object, 'mangle' it by replacing all properties with a caller
  transparent proxy. The intention is that this is used to intercept property
  sets on data objects as returned via JSON.
  
  @param {Function} before proxy intercepts just before a write
  @param {Function} after proxy intercepts just after a write
  @param {Object} options proxy passes this along to all before/after handlers
  @param {Array} parents a 'path' of parent references, passes to all before/after handlers
  @returns {Object} this echoes the proxied object to allow chaining
  
  The before and after callbacks are of the form
  (object, property, value, options, parents)
  allowing you to have some context on where a named property changed.
  */


  Object.defineProperty(Object.prototype, 'proxy', {
    enumerable: false,
    configurable: true,
    writeable: false,
    value: function(before, after, options, parents) {
      return proxyObject(this, before, after, options, parents);
    }
  });

  proxyObject = function(object, before, after, options, parents) {
    var handler, mutator, name, value, _fn, _i, _len;
    if (!object) {
      return null;
    }
    if (typeof object !== 'object') {
      return object;
    }
    if (!(object != null ? object.__proxied__ : void 0)) {
      Object.defineProperty(object, '__proxied__', {
        enumerable: false,
        value: {}
      });
    }
    before = before || function() {};
    after = after || function() {};
    options = options || {};
    parents = (parents != null ? parents.slice(0) : void 0) || [this];
    parents.unshift(object);
    handler = function(property, before_value, after_value) {
      if (typeof after_value === 'object') {
        proxyObject(after_value, before, after, options, parents);
      }
      before(object, property, before_value, options, parents);
      after(object, property, after_value, options, parents);
      return after_value;
    };
    for (name in object) {
      value = object[name];
      if (Array.isArray(value)) {
        _fn = function() {
          var array, prior;
          array = value;
          prior = array[mutator];
          return Object.defineProperty(array, mutator, {
            enumerable: false,
            configurable: true,
            writeable: false,
            value: function() {
              var argument, ret, _j, _len1;
              before(object, name, array, options, parents);
              ret = prior.apply(array, arguments);
              for (_j = 0, _len1 = arguments.length; _j < _len1; _j++) {
                argument = arguments[_j];
                proxyObject(argument, before, after, options, parents);
              }
              after(object, name, array, options, parents);
              return ret;
            }
          });
        };
        for (_i = 0, _len = array_mutators.length; _i < _len; _i++) {
          mutator = array_mutators[_i];
          _fn();
        }
      }
      value = proxyObject(value, before, after, options, parents);
      if (!object.__proxied__[name]) {
        object.watch(name, handler);
        object.__proxied__[name] = true;
      }
    }
    return object;
  };

  /*
  @module react
  */


  before = function(object, property, value, options, parents) {
    return parents.forEach(function(parent) {
      var _ref;
      return parent != null ? (_ref = parent.__react__) != null ? _ref.before.forEach(function(reaction) {
        return reaction(object, property, value);
      }) : void 0 : void 0;
    });
  };

  after = function(object, property, value, options, parents) {
    return parents.forEach(function(parent) {
      var _ref;
      return parent != null ? (_ref = parent.__react__) != null ? _ref.after.forEach(function(reaction) {
        return reaction(object, property, value);
      }) : void 0 : void 0;
    });
  };

  /*
  @method react
  
  Create a proxy with reactive data that bubbles data change events up a
  JavaScript object similar to event bubbling on the DOM. This works on a bare,
  un-proxied JavaScript object.
  
  @param {String} action one or more of the following space separated
      before: event handler before properties are changed
      after: event handler after properties are changed
      off: remove event handlers
  @param {Function} callback a function of the form (object, property, value) that is an event callback.
  */


  Object.defineProperty(Object.prototype, 'react', {
    enumerable: false,
    configurable: true,
    writable: false,
    value: function(action, callback) {
      var _i, _len, _ref;
      if (action) {
        if (!this.__react__) {
          Object.defineProperty(this, '__react__', {
            enumerable: false,
            configurable: true,
            writable: false,
            value: {
              before: [],
              after: []
            }
          });
        }
        _ref = action.toLowerCase().split(' ');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          action = _ref[_i];
          if (action === 'off') {
            if (this.__react__) {
              delete this.__react__;
            }
          } else if (this.__react__[action]) {
            this.__react__[action].push(callback);
          }
        }
      }
      return this.proxy(before, after);
    }
  });

}).call(this);
