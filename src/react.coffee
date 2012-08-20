###
@module react
@requires jQuery

Provides reactive data aspect oriented programming for JavaScript.
###


$ = jQuery
$.fn.react = (action, callback) ->
    #these are the callback chains, and will be keyed by the 
    #binding object in the jQuery each loop
    callbacks =
        before: {}
        after: {}
    #these are the callback chain entry points used to proxy objects
    #these aren't closures at all, they will use the parent chain
    #to figure which callbacks to run
    before = (object, property, value, options, parents) ->
        parents.forEach (parent) ->
            callbacks.before?[parent]?.fire object, property, value
        
    after = (object, property, value, options, parents) ->
        parents.forEach (parent) ->
            callbacks.after?[parent]?.fire object, property, value

    @each (i, el) ->
        buffer = callbacks[action][el] or jQuery.Callbacks('unique stopOnFalse')
        buffer.add callback
        callbacks[action][el] = buffer
        #each object needs to be proxied
        proxyObject el, before, after

