###
Let's test the ability to create a very general purpose event generating proxy
wrapper around any old object.

...it's a valid question to ask if this is useful enough to be its own stand
alone library...
###

require '../src/watch'
require '../src/proxy'
expect = require 'expect.js'


describe 'object proxy', ->

    #this is sort of like a transaction log on property access
    before = []
    after = []

    beforeEach ->
        before = []
        after = []

    #these are cloning interceptors
    intercept_before = (object, property, value, options) ->
        if typeof(value) is 'object'
            value = JSON.parse(JSON.stringify(value))
        before.push [property, value]

    intercept_after = (object, property, value, options) ->
        if typeof(value) is 'object'
            value = JSON.parse(JSON.stringify(value))
        after.push [property, value]

    it 'changes an object into a proxy', ->
        x =
            a: 1
        y = x.proxy()
        expect(y).to.be(x)

    it 'proxies an object with scalar properties', ->
        x =
            a: 1
            b: 2
        x.proxy intercept_before, intercept_after
        x.a = 11
        x.b = 22
        expect(before).to.eql [
            ['a', 1],
            ['b', 2]
        ]
        expect(after).to.eql [
            ['a', 11],
            ['b', 22]
        ]

    it 'proxies into an object with array properties', ->
        x =
            a: []
        x.proxy intercept_before, intercept_after

        x.a.push 1
        x.a.push 2
        x.a.unshift 0
        expect(x.a.pop()).to.equal 2
        expect(x.a.shift()).to.equal 0
        x.a.push 2
        expect(x.a.reverse()).to.eql [2,1]
        expect(x.a.sort()).to.eql [1,2]
        expect(x.a.splice(0,2,'a','b')).to.eql [1,2]
        expect(x.a).to.eql ['a','b']

        #just check the operations before and after arrays at the end
        expect(before).to.eql [
            ['a', []],
            ['a', [1]],
            ['a', [1,2]]
            ['a', [0,1,2]]
            ['a', [0,1]],
            ['a', [1]],
            ['a', [1,2]],
            ['a', [2,1]],
            ['a', [1,2]],
        ]
        expect(after).to.eql [
            ['a', [1]],
            ['a', [1,2]],
            ['a', [0,1,2]]
            ['a', [0,1]]
            ['a', [1]],
            ['a', [1,2]],
            ['a', [2,1]],
            ['a', [1,2]],
            ['a', ['a','b']],
        ]

    it 'proxies an array member set', ->
        x =
            a: [1]
        x.proxy intercept_before, intercept_after

        x.a[0] = 0
        x.a.push 1
        x.a[1] = 2
        expect(before).to.eql [
            ['0', 1],
            ['a', [0]],
            ['1', 1],
        ]
        expect(after).to.eql [
            ['0', 0],
            ['a', [0,1]],
            ['1', 2],
        ]

    it 'proxies nested objects properties', ->
        x =
            a:
                b: ''

        x.proxy intercept_before, intercept_after

        x.a.b = 1
        expect(before).to.eql [
            ['b', '']
        ]
        expect(after).to.eql [
            ['b', 1]
        ]

    it 'proxies objects as they are added to a proxied object', ->
        x =
            a: null

        x.proxy intercept_before, intercept_after
        x.a = {b: ''}
        expect(x.a).to.eql {b: ''}
        expect(x.a).to.have.property '__proxied__'
        x.a.b = 1
        expect(before).to.eql [
            ['a', null],
            ['b', '']
        ]
        expect(after).to.eql [
            ['a', {b: ''}],
            ['b', 1]
        ]

    it 'will not double proxy', ->
        x =
            a: null
        x.proxy intercept_before, intercept_after
        x.proxy intercept_before, intercept_after
        expect(x.__proxied__.a).to.equal true
        x.a = 1
        expect(before).to.eql [
            ['a', null],
        ]
        expect(after).to.eql [
            ['a', 1]
        ]

    it 'will proxy objects added to proxied arrays', ->
        x =
            a: []
        x.proxy intercept_before, intercept_after

        x.a.push
            b: 1
        x.a[0].b = 2

        expect(before).to.eql [
            ['a', []],
            ['b', 1],
        ]
        expect(after).to.eql [
            ['a', [b: 1]],
            ['b', 2]
        ]

    it 'gives you the parent', ->
        x =
            a:
                b: 1
            c: 'a'
        parent = null
        x.proxy (_, __, ___, options, parents) ->
            parent = parents[0]
        #note we are two deep here
        x.a.b = 2
        expect(parent).to.be x.a
        #note we are one deep here
        x.c = 'b'
        expect(parent).to.be x

    it 'forgives you if you forget callbacks', ->
        x =
            a: 1
        expect((-> x.proxy())).to.not.throwException()
        expect((-> x.a = 2)).to.not.throwException()
