###
@module react


###

#these are the callback chain entry points used to proxy objects
#these aren't closures at all, they will use the parent chain
#to figure which callbacks to run
before = (object, property, value, options, parents) ->
    parents.forEach (parent) ->
        parent?.__react__?.before.forEach (reaction) ->
            reaction object, property, value

after = (object, property, value, options, parents) ->
    parents.forEach (parent) ->
        parent?.__react__?.after.forEach (reaction) ->
            reaction object, property, value


###
@method react

Create a proxy with reactive data that bubbles data change events up a
JavaScript object similar to event bubbling on the DOM. This works on a bare,
un-proxied JavaScript object.

@param {String} action one or more of the following space separated
    before: event handler before properties are changed
    after: event handler after properties are changed
    off: remove event handlers
@param {Function} callback a function of the form (object, property, value) that is an event callback.
###
Object.defineProperty Object.prototype, 'react',
    enumerable: false
    configurable: true
    writable: false
    value: (action, callback) ->
        #if there are no arguments, this is just a re-proxy
        if action
            #hook up the callbacks here, this has the effect of registering just
            #in one place rather than all over an object graph
            if not this.__react__
                Object.defineProperty this, '__react__',
                    enumerable: false
                    configurable: true
                    writable: false
                    value:
                        before: []
                        after: []
            for action in action.toLowerCase().split(' ')
                if action is 'off'
                    #all the bindings are just deleted
                    if this.__react__
                        delete this.__react__
                else if this.__react__[action]
                    this.__react__[action].push callback
        #each object needs to be proxied to provide a callback hookup
        this.proxy before, after

