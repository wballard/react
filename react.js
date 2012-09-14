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

Provides the ability to wrap any object with a proxy that sets up interception
callbacks on any property set or nested array mutation. This sets a foundation
for aspect oriented style JavaScript.

You can use this standalone, separate from the rest of binder.

Proxied properties are tracked in __proxied__, which is made non-enumerable
via Object.defineProperty in order to keep it out of JSON going back to your
server, as well as showing up in normal loop iteration. Be warned that on
IE8 that needs a Object.defineProperty polyfill, this can end up visible.
*/


/*
@private
List of methods on Array that mutate it in place.
*/


(function() {
  var array_mutators, proxyObject, root;

  array_mutators = ['push', 'unshift', 'pop', 'shift', 'reverse', 'sort', 'splice'];

  /*
  @function
  
  Given an object, 'mangle' it by replacing all properties with a caller
  transparent proxy. The intention is that this is used to intercept property
  sets on data objects as returned via JSON.
  
  @param object {Object} this object will be proxied in place
  @param before {Function} proxy intercepts just before a write
  @param after {Function} proxy intercepts just after a write
  @returns {Object} this echoes the proxied object to allow chaining
  
  The before and after callbacks are of the form
  (object, property, value, options)
  allowing you to have some context on where a named property changed.
  */


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
          var prior;
          prior = value[mutator];
          return value[mutator] = function() {
            var argument, ret, _j, _len1;
            before(object, name, value, options, parents);
            ret = prior.apply(value, arguments);
            for (_j = 0, _len1 = arguments.length; _j < _len1; _j++) {
              argument = arguments[_j];
              proxyObject(argument, before, after, options, parents);
            }
            after(object, name, value, options, parents);
            return ret;
          };
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

  root = this;

  if ((typeof module !== "undefined" && module !== null) && (typeof module !== "undefined" && module !== null ? module.exports : void 0)) {
    root = module.exports;
  }

  if (!(root != null ? root.binder : void 0)) {
    root.binder = {};
  }

  root.proxyObject = proxyObject;

}).call(this);
