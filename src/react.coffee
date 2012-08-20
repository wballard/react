###
@module react
@requires jQuery

Provides reactive data aspect oriented programming for JavaScript.
###

#these are the callback chains, and will be keyed by the 
#binding object in the jQuery each loop, they are here at the
#top level to not be bound by the react closure
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

$ = jQuery
$.fn.react = (action, callback) ->
    #work on a set of just plain objects, which makes working with data
    #feel like working with jQuery
    @each (i, el) ->
        #hook up the callbacks here, this has the effect of registering just
        #in one place rather than all over an object graph
        for action in action.toLowerCase().split(' ')
            if action is 'off'
                #all the bindings are just deleted
                delete callbacks.before[el]
                delete callbacks.after[el]
            else
                buffer = callbacks[action][el] or jQuery.Callbacks('unique stopOnFalse')
                buffer.add callback
                callbacks[action][el] = buffer
        #each object needs to be proxied to provide a callback hookup
        proxyObject el, before, after

