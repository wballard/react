###
@module react
@requires jQuery

Provides reactive data aspect oriented programming for JavaScript.
###

#these are the callback chain entry points used to proxy objects
#these aren't closures at all, they will use the parent chain
#to figure which callbacks to run
before = (object, property, value, options, parents) ->
    parents.forEach (parent) ->
        parent?.__react__?.before.fire object, property, value

after = (object, property, value, options, parents) ->
    parents.forEach (parent) ->
        parent?.__react__?.after.fire object, property, value

$ = jQuery
$.fn.react = (action, callback) ->
    #work on a set of just plain objects, which makes working with data
    #feel like working with jQuery
    @each (i, el) ->
        #if there are no arguments, this is just a re-proxy
        if action
            #hook up the callbacks here, this has the effect of registering just
            #in one place rather than all over an object graph
            if not el.__react__
                Object.defineProperty el, '__react__',
                    enumerable: false
                    configurable: true
                    value:
                        before: jQuery.Callbacks('unique stopOnFalse')
                        after: jQuery.Callbacks('unique stopOnFalse')
            for action in action.toLowerCase().split(' ')
                if action is 'off'
                    #all the bindings are just deleted
                    if el.__react__
                        delete el.__react__
                else
                    el.__react__[action].add callback
        #each object needs to be proxied to provide a callback hookup
        proxyObject el, before, after

