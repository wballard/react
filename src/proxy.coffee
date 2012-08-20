###
@module proxy

Provides the ability to wrap any object with a proxy that sets up interception
callbacks on any property set or nested array mutation. This sets a foundation
for aspect oriented style JavaScript.

You can use this standalone, separate from the rest of binder.
###

###
@private
List of methods on Array that mutate it in place.
###
array_mutators = ['push', 'unshift', 'pop', 'shift', 'reverse', 'sort', 'splice']

###
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
###
proxyObject = (object, before, after, options, parents) ->
    if not object
        return null
    if typeof(object) != 'object'
        return object
    if object?.__proxied__
        return object
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
                    prior = value[mutator]
                    value[mutator] = ->
                        before object, name, value, options, parents
                        ret = prior.apply value, arguments
                        for argument in arguments
                            #parent is the array, not the containing object
                            proxyObject argument, before, after, options, parents
                        after object, name, value, options, parents
                        ret)()
        #recursive proxy
        value = proxyObject value, before, after, options, parents
        #watch every property to call our function
        object.watch name, handler

    #create a guard so we can avoid double proxy, that isn't enumerable
    #since we don't want it showing up in JSON
    Object.defineProperty object, '__proxied__',
        enumerable: false
        value: true
    object

#Export the proxy to the passed this or as a CommonJS module
#if that's available.
root = this
if module? and module?.exports
    root = module.exports
if not root?.binder
    root.binder = {}
root.proxyObject = proxyObject
