beforeEach ->
    @addMatchers 
        toBeProxied: (expected) ->
            @actual?.__proxied__
