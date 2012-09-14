###
@module proxy

Provides the ability to wrap any object with a proxy that sets up
interception callbacks on any property set or nested array mutation.
This sets a foundation for aspect oriented style JavaScript.

Proxied properties are tracked in `__proxied__`, which is made
non-enumerable via Object.defineProperty in order to keep it out of
JSON going back to your server, as well as showing up in normal loop
iteration. Be warned that on IE8 that needs a `Object.defineProperty`
polyfill, this can end up visible.

###

###
@private
List of methods on Array that mutate it in place.
###
array_mutators = ['push',
    'unshift',
    'pop',
    'shift',
    'reverse',
    'sort',
    'splice']

###
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
###
Object.defineProperty Object.prototype, 'proxy',
    enumerable: false
    configurable: true
    writeable: false
    value: (before, after, options, parents) ->
        proxyObject this, before, after, options, parents

proxyObject = (object, before, after, options, parents) ->
    if not object
        return null
    if typeof(object) != 'object'
        return object
    if not object?.__proxied__
        #create a guard so we can avoid double proxy, that isn't enumerable
        #since we don't want it showing up in JSON
        Object.defineProperty object, '__proxied__',
            enumerable: false
            value: {}
    before = before or () ->
    after = after or () ->
    options = options or {}
    parents = parents?.slice(0) or [this]
    parents.unshift object

    #Define a handler closure for this object being proxied
    #to be used from watch. This is the interception point that
    #connects the before and after callbacks.
    handler = (property, before_value, after_value) ->
        #objects need to be proxied when added to an object
        if typeof(after_value) == 'object'
            proxyObject after_value, before, after, options, parents
        before object, property, before_value, options, parents
        after object, property, after_value, options, parents
        after_value

    #every enumerable property will be proxied
    for name, value of object
        #arrays need their mutation methods intercepted
        if Array.isArray value
            for mutator in array_mutators
                (->
                    array = value
                    prior = array[mutator]
                    Object.defineProperty array, mutator,
                        enumerable: false
                        configurable: true
                        writeable: false
                        value: ->
                            before object, name, array, options, parents
                            ret = prior.apply array, arguments
                            for argument in arguments
                                #parent is the array, not the containing object
                                proxyObject argument, before, after, options, parents
                            after object, name, array, options, parents
                            ret)()
        #recursive proxy
        value = proxyObject value, before, after, options, parents
        #watch every property to call our function, but only just the once
        if not object.__proxied__[name]
            object.watch name, handler
            object.__proxied__[name] = true

    object
